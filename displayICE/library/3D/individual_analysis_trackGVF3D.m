function [traj_map, sink] = individual_analysis_trackGVF3D(f,dx,dy,dz,T,Barrier)
% [traj_map, sink, marker] = individual_analysis_trackGVF(f,dx,dy,T)
%
%------------------------------Description---------------------------------
%
% Takes an image with its gradient vector field and segments it by
% collecting together the points that lead to the same sink point when
% allowed to flow along the gradient field (we say those points belong to
% the same gradient flow trajectory)
%
% -------------------------------Input-------------------------------------
%
% f         : Image file (2-D matrix)
% dx        : x-component of the gradient vector field of f
% dy        : y-component of the gradient vector field of f
% dz        : z-component of the gradient vector field of f
% T         : Thresholds that separates the neurons from the background
%
% ------------------------------Output-------------------------------------
%
% traj_map  : Segmented image where each point belongs to a gradient flow
%             trajectory (labelled with an integer) determined by its sink
% sink      : n x 3 matrix recording n trajectories. First column contains
%             the indicator number for the trajectory, second and third
%             columns contain r- and c-coordinate of the sink point
%             respectively.
% marker    : Total number of trajectories
%
% ------------------------------Notes--------------------------------------
%
% Two coordinate systems are used: Cartesian (x,y) and row-column (r,c)
% Cartesian objects: dx, dy
% Row-column objects: sink
% Keep in mind: x <-> c and y <-> r.
% In general, (r,c) is used to manipulate matrices while
% (x,y) is used to plot graphs (such as function plot)
% 130626 halvens the runtime of v2 by using c_traj
% 130709 separates the region-merging process
% 140306 Added tracking with barrier

traj_map = zeros(size(dx)); % Records particles belonging to a flow trajectory
sink = NaN(numel(dx),4);    % Keeps track of sinks that correspond to each flow trajectory (first index is the indicator, 2nd and 3rd the sink coordinate in (r,c)) (Preallocation for the maximum possible number of trajectories)
marker = 0;                 % Indicator for different flow trajectories (Current marker value is the total number of trajectories tracked thus far)
c_traj = cell(1,numel(dx)); % Keeps track of particles belonging to a flow trajectory

%% Initial Tracking & Segmenting
for r = 1:size(dx,1)    % Loop through every point in the image
    for c = 1:size(dx,2)
        for z = 1:size(dz,3)
            gc_init = dx(r,c,z);    % Gradient at that point
            gr_init = dy(r,c,z);    % Gradient at that point
            gz_init = dz(r,c,z);    % Gradient at that point
            
            if (traj_map(r,c,z) ~= 0) || ...                % If the point belongs to a trajectory
               (gc_init==0&&gr_init==0&&gz_init==0) || ...  % or has zero gradient
                Barrier(r,c,z) == 1  
                continue    % Skip
            end
            
            marker = marker + 1;    % Start a new trajectory
            r_old = r;
            c_old = c;
            z_old = z;
            
            % Loop to create a trajectory
            while true  % See loop break conditions below
                break_cond = 0; % 1 indicates loop break condition satisfied
                
                traj_map(r_old,c_old,z_old) = marker;   % Assign the point to a trajectory
                c_traj{marker} = cat(1,c_traj{marker}, [r_old,c_old,z_old]);
                
                gc_old = dx(r_old,c_old,z_old);   % Components of the old gradient vector
                gr_old = dy(r_old,c_old,z_old);
                gz_old = dz(r_old,c_old,z_old);
                len_old = sqrt(gc_old.^2 + gr_old.^2 + gz_old.^2);  % Length of the old gradient vector
                
                % New point calculated by taking a unit step in the direction
                r_new = r_old + round(gr_old/len_old);
                c_new = c_old + round(gc_old/len_old);
                z_new = z_old + round(gz_old/len_old);
                
                % This block determines whether the loop should end
                if len_old == 0     % If the old gradient is zero
                    sink(marker,1) = marker;
                    sink(marker,2) = r_old;
                    sink(marker,3) = c_old;
                    sink(marker,4) = z_old;
                    break_cond = 1;
                elseif r_new < 1 || r_new > size(dx,1) || ...
                       c_new < 1 || c_new > size(dx,2) || ...
                       z_new < 1 || z_new > size(dz,3) || ...
                       Barrier(r_new,c_new,z_new) == 1
                    sink(marker,1) = marker;
                    sink(marker,2) = r_old;
                    sink(marker,3) = c_old;
                    sink(marker,4) = z_old;
                    break_cond = 1;
                else
                    gc_new = dx(r_new,c_new,z_new);
                    gr_new = dy(r_new,c_new,z_new);
                    gz_new = dz(r_new,c_new,z_new);
                    
                    len_new = sqrt(gc_new.^2 + gr_new.^2 + gz_new.^2);
                    
                    dot_prod = gc_old*gc_new + gr_old*gr_new + gz_old*gz_new;
                    theta = acos(dot_prod/(len_old*len_new));
                    
                    indicator_new = traj_map(r_new,c_new,z_new);    % The affiliation of the candidate point
                    
                    % See if this new point indicates that the loop has been finished
                    if indicator_new ~= 0
                        if marker ~= indicator_new
                            c_traj{indicator_new} = cat(1,c_traj{indicator_new}, c_traj{marker});
                            for i = 1:size(c_traj{marker},1)
                                traj_map(c_traj{marker}(i,1), c_traj{marker}(i,2), c_traj{marker}(i,3)) = indicator_new;
                            end
                            c_traj{marker} = [];
                            marker = marker - 1;
                            break_cond = 1;
                        else
                            disp('Uh Oh')
                            sink(marker,1) = marker;
                            sink(marker,2) = r_old; % Arbitrary sink point
                            sink(marker,3) = c_old;
                            sink(marker,4) = z_old;
                            break_cond = 1;
                        end
                    elseif theta > pi/2
                        sink(marker,1) = marker;
                        sink(marker,2) = r_old;
                        sink(marker,3) = c_old;
                        sink(marker,4) = z_old;
                        break_cond = 1;
                    end
                end
                
                if break_cond
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

sink = sink(1:marker,:);    % Clean up unused spots

%% Find centre of the particle

% Get the point closest to the centre

dimR = size(f,1);   % Dimensions of the image
dimC = size(f,2);
dimZ = size(f,3);

% Centre of the image
r_centre = (1 + dimR) / 2;
c_centre = (1 + dimC) / 2;
z_centre = (1 + dimZ) / 2;

dist = zeros(size(sink,1), 1);

for i = 1:size(sink,1)
    
    if f(sink(i,2),sink(i,3),sink(i,4)) >= T(sink(i,4));
        dist(i) = sqrt( (sink(i,2) - r_centre).^2 + (sink(i,3) - c_centre).^2 + (sink(i,4) - z_centre).^2 );   % Distance from the centre
    else
        dist(i) = inf;
    end
    
end

min_index = find(dist == min(dist), 1); % Sink point closest to the centre

% We have selected the centre of the particle
sink_indicator = sink(min_index,1);
r_sink = sink(min_index,2);
c_sink = sink(min_index,3);
z_sink = sink(min_index,4);

%% Merge

sink_conv_dist = 10;     % Merge the trajectories only if their sink points are less than this distance away

dist = [sink(:,1), sqrt( (sink(:,2) - r_sink).^2 + (sink(:,3) - c_sink).^2 + (sink(:,4) - z_sink).^2)];
dist(min_index,:) = []; % Remove the current sink under consideration

merge_candidates = dist(:,2) < sink_conv_dist;  % Get the candidates satisfying maximum distance
merge_candidate_ids = dist(merge_candidates);   % Get the identifier of the candidates

% Merge
for j = merge_candidate_ids'
    traj_map(traj_map == j) = sink_indicator;
end

% Cut off other regions
traj_map(traj_map ~= sink_indicator) = 0;

% Cut off unconnected regions
connectivity = bwconncomp(traj_map);
if (connectivity.NumObjects > 1)
    traj_map = bwlabeln(traj_map);
end

id = traj_map(r_sink,c_sink,z_sink);   % Region that contains the sink point
traj_map = traj_map == id;

sink = [r_sink, c_sink, z_sink];