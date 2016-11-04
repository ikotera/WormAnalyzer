function [traj_map, traj, sink, dx, dy, dz] = grad_flow_segm3D(f)
% [segm, num_segm, sink, dx, dy, dz] = grad_flow_segm3D(f)
%
%------------------------------Description---------------------------------
%
% Segments the given image stack by determining its gradient vector field 
% and collecting together the points that lead to the same sink 
%
% -------------------------------Input-------------------------------------
%
% f         : Image stack (3-D matrix)
%
% ------------------------------Output-------------------------------------
%
% segm          : Segmented image stack of f with each region labelled with a
%                 different integer
% num_segm      : Total number of segmented regions
% sink          : num_seg x 4 matrix where the first column contains region
%                 identifiers (integer), second to fourth columns contain
%                 row, column, and z-coordinates 
% dx, dy, dz    : Gradient vector field used for segmentation

%% Gradient vector field

dimR = size(f,1);
dimC = size(f,2);
dimZ = size(f,3);

[dx, dy, dz] = gradient(double(f)); % Gradient vector field
f = mat2gray(f);

T = zeros(1,dimZ);
for i = 1:dimZ
    T(i) = graythresh(f(:,:,i));
end

%% Initial Tracking & Segmenting
startInit = tic;

traj_map = zeros(size(f));  % Records particles belonging to a flow trajectory
sink = NaN(numel(f),4);     % Records sinks that correspond to each flow trajectory (1st index = indicator, 2nd/3rd/4th = sink coordinate)
traj = 0;                   % Indicator for different flow trajectories (Current traj value is the total number of trajectories tracked thus far)
c_traj = cell(1,numel(dx)); % Keeps track of particles belonging to a flow trajectory

for r = 1:dimR  % Loop through every pixel in the image
    for c = 1:dimC
        for z = 1:dimZ
            gc_init = dx(r,c,z);  % Gradient at that point
            gr_init = dy(r,c,z);
            gz_init = dz(r,c,z);
            
            if traj_map(r,c,z) ~= 0 || ...                      % If the point belongs to a trajectory
                (gc_init == 0 && gr_init == 0 && gz_init == 0)  % or has zero gradient
                continue
            else
                
                traj = traj + 1;    % Start a new trajectory
                r_old = r;          % Initial point
                c_old = c;
                z_old = z;
                
                % Loop to create a trajectory
                while true  % See loop break conditions below
                    break_cond = 0; % 1 indicates loop break condition satisfied
                    
                    traj_map(r_old,c_old,z_old) = traj;   % Assign the point to a trajectory
                    c_traj{traj} = cat(1,c_traj{traj},[r_old c_old z_old]);
                    
                    gc_old = dx(r_old,c_old,z_old);
                    gr_old = dy(r_old,c_old,z_old);
                    gz_old = dz(r_old,c_old,z_old);
                    len_old = sqrt(gc_old.^2 + gr_old.^2 + gz_old.^2);  % Length of the old gradient vector
                    
                    % New point calculated by taking a unit step in the direction of the old gradient vector
                    r_new = r_old + round(gr_old/len_old);
                    c_new = c_old + round(gc_old/len_old);
                    z_new = z_old + round(gz_old/len_old);
                    
                    % This block determines whether the loop should end or not
                    if len_old == 0                             % If the old gradient is zero
                        sink(traj,1) = traj;                % The old point is the sink
                        sink(traj,2) = r_old;
                        sink(traj,3) = c_old;
                        sink(traj,4) = z_old;
                        break_cond = 1;
                    elseif r_new < 1 || r_new > dimR || ...     % If the new point out of bound
                           c_new < 1 || c_new > dimC || ...
                           z_new < 1 || z_new > dimZ
                        sink(traj,1) = traj;                % Let the last point be the sink
                        sink(traj,2) = r_old;
                        sink(traj,3) = c_old;
                        sink(traj,4) = z_old;
                        break_cond = 1;
                    else                                        % Otherwise we have a valid new point
                        gc_new = dx(r_new,c_new,z_new);         % Components of the new gradient vector
                        gr_new = dy(r_new,c_new,z_new);
                        gz_new = dz(r_new,c_new,z_new);
                        
                        len_new = sqrt(gc_new.^2 + gr_new.^2 + gz_new.^2);          % Length of the new gradient vector
                    
                        dot_prod = gc_old*gc_new + gr_old*gr_new + gz_old*gz_new;   % Dot product between the old and new gradient vectors
                        theta = acos(dot_prod/(len_old*len_new));                   % The angle between two gradient vectors
                        
                        indicator_new = traj_map(r_new,c_new,z_new);  % The affiliation of the candidate point
                        
                        % See if this new point indicates that the loop has been finished
                        if indicator_new ~= 0                   % If the new pixel belongs to a trajectory
                            if traj ~= indicator_new          % If the already-reached trajectory is not the current one
                                c_traj{indicator_new} = cat(1,c_traj{indicator_new},c_traj{traj});    % Assign the pixels in the current trajectory to the previous one
                                for i = 1:size(c_traj{traj},1)
                                    traj_map(c_traj{traj}(i,1), c_traj{traj}(i,2), c_traj{traj}(i,3)) = indicator_new;
                                end
                                c_traj{traj} = [];
                                traj = traj - 1;    % Reset the current trajectory indicator
                                break_cond = 1;         % Done
                                
                            else                                % Circular loop
                                disp('Uh Oh');
                                sink(traj,1) = traj;
                                sink(traj,2) = r_old;         % Arbitrary sink point
                                sink(traj,3) = c_old;
                                sink(traj,4) = z_old;
                                break_cond = 1;
                            end
                        elseif theta > pi/2             % Sink reached if more than 90 degrees turn
                            sink(traj,1) = traj;
                            sink(traj,2) = r_old;
                            sink(traj,3) = c_old;
                            sink(traj,4) = z_old;
                            break_cond = 1;
                        end
                    end
                    
                    if break_cond
                        %num_traj = size(c_traj{traj},1);
                        % Check for minimum size of trajectory condition
                        %if num_traj < min_n
                        %    traj_map(traj_map == traj) = 0;
                        %    c_traj{traj} = [];
                        %    sink(traj, 1) = NaN;
                        %    sink(traj, 2) = NaN;
                        %    sink(traj, 3) = NaN;
                        %    sink(traj, 4) = NaN;
                        %    traj = traj - 1;
                        %end
                        
                        break;
                    end
                    
                    % With the new point, repeat the loop
                    r_old = r_new;
                    c_old = c_new;
                    z_old = z_new;

                end
            end
        end
    end
end

sink = sink(1:traj, :);   % Clean up unused spots
endInit = toc(startInit);

%% Region merging
tic;
sink_conv_dist = 10; % Merge the trajectories only if their sink points are less than this distance away
min_n = 30;          % Minimum number of voxels that a particle must have

i = 1;
while i <= size(sink,1) % Loop through all sink points
    disp([num2str(i), '/', num2str(size(sink,1))])
    r_cor = sink(i,2);  % Get the coordinates
    c_cor = sink(i,3);
    z_cor = sink(i,4);
    identifier = sink(i,1);
    if isnan(identifier)
        i = i + 1;
        continue
    end
    
    if f(r_cor,c_cor,z_cor) >= T(z_cor) % If the sink belongs to a bright spot
        destroy = 0;
        
        dist = [sink(:,1), sink(:,2) - r_cor, sink(:,3) - c_cor, abs(sink(:,4) - z_cor)];
        dist(i,:) = []; % Remove the current sink under consideration
        
        dist(dist(:,4) > 1, :) = [];  % Remove the points more than one z-level away
        
        dist = [dist(:,1), sqrt(dist(:,2).^2 + dist(:,3).^2)];  % Distances from the current sink point
        merge_candidates = dist(:,2) < sink_conv_dist;          % Get the candidates satisfying max distance
        
        merge_candidate_marks = dist(merge_candidates);         % Get the identifier of the candidates
        
        combined_map = traj_map == identifier;
        for j = merge_candidate_marks'
            combined_map = combined_map + (traj_map == j);
        end
        
        connected_map = bwlabeln(combined_map);
        connected_particle = connected_map == connected_map(r_cor,c_cor,z_cor);
        if nnz(connected_particle) >= min_n  % If the connected block satisfies as a particle

            for j = merge_candidate_marks'  % Pick out sinks that are part of the combined particle
              
                if connected_particle(sink(j,2),sink(j,3),sink(j,4)) == 1
                    traj_map(traj_map == j) = identifier;
                    
                    if find(sink(:,1) == j) <= i
                        i = i - 1; % If previous point, pull back
                    end
                    
                    sink(sink(:,1) == j,:) = [NaN NaN NaN NaN];    % Take out the merged sink point
                    traj = traj - 1;    % Number of trajectories decreased by 1
                end
            end
                

        else    % Otherwise
            destroy = 1;
        end

    else                            % If the sink belongs to background
        destroy = 1;
    end
    
    % Destroy the trajectory
    if destroy
        traj_map(traj_map == identifier) = 0;   % Destroy the trajectory
        sink(i,:) = [NaN NaN NaN NaN];
        traj = traj - 1;    % Number of trajectories decreased by 1
        i = i - 1;  % Since we just destroyed the ith trajectory
    end
    
    i = i + 1;
end

% Remove NaNed sinks

sink = sink(~any(isnan(sink),2),:);

traj_map = uint16(traj_map);    % Convert to 16-bit

toc;