function [traj_map, sink, marker] = gradient_flow_track(f,dx,dy,filters)
% [traj_map, sink, marker] = gradient_flow_track(f,dx,dy,T)
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
% T         : Threshold that separates the neurons from the background
T = (filters.threshBack * filters.multiplier) / 2^16;
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

traj_map = zeros(size(dx)); % Records particles belonging to a flow trajectory
sink = NaN(numel(dx),3);    % Keeps track of sinks that correspond to each flow trajectory (first index is the indicator, 2nd and 3rd the sink coordinate in (r,c)) (Preallocation for the maximum possible number of trajectories)
marker = 0;                 % Indicator for different flow trajectories (Current marker value is the total number of trajectories tracked thus far)
min_n = 1;                  % Minimum number of pixels that a trajectory must have
c_traj = cell(1,numel(dx)); % Keeps track of particles belonging to a flow trajectory

%% Initial Tracking & Segmenting
for r = 1:size(dx,1)        % Loop through every point in the image (Note: Can there be a more efficient way? Looks difficult)
    for c = 1:size(dx,2)
        gc_init = dx(r,c);                  % gradient at that point
        gr_init = dy(r,c);
        if (traj_map(r,c) == 0) && ...      % If the point does not belong to a trajectory
            (gc_init ~= 0 || gr_init ~= 0)  % And has nonzero gradient
            marker = marker + 1;            % Start a new trajectory
            r_old = r;                      % Initial point becomes the old point
            c_old = c;
            
            % Loop to create a trajectory
            while true      % See loop break conditions below
                valid_traj = 0;                             % Becomes 1 when valid trajectory candidate is obtained
                break_cond = 0;                             % Becomes 1 when it's time to break out
                
                c_traj{marker} = cat(1,c_traj{marker},[r_old c_old]);             % Assign the point to the current trajectory indicator
                traj_map(r_old, c_old) = marker;
                
                gc_old = dx(r_old,c_old);                   % Components of the old gradient vector
                gr_old = dy(r_old,c_old);
                
                len_old = sqrt(gc_old.^2 + gr_old.^2);      % Length of the old gradient vector
                
                % New point calculated by taking a unit step in the direction of the old gradient vector
                r_new = r_old + round(gr_old/len_old);
                c_new = c_old + round(gc_old/len_old);
                
                if isnan(r_new) || isnan(c_new)                 % If the old gradient is zero
                    sink(marker,1) = marker;                    % The old point is the sink
                    sink(marker,2) = r_old;
                    sink(marker,3) = c_old;
                    valid_traj = 1;
                elseif r_new < 1 || r_new > size(dx,1) || ...   % If the new point out of bound
                       c_new < 1 || c_new > size(dx,2)
                    sink(marker,1) = marker;                    % Let the last point be the sink
                    sink(marker,2) = r_old;
                    sink(marker,3) = c_old;
                    valid_traj = 1;
                else                                            % Otherwise we have a valid new point
                    gc_new = dx(r_new,c_new);                   % Components of the new gradient vector
                    gr_new = dy(r_new,c_new);
                
                    len_new = sqrt(gc_new.^2 + gr_new.^2);      % Length of the new gradient vector
                    
                    dot_prod = gc_old*gc_new + gr_old*gr_new;   % Dot product between the old and new gradient vectors
                    theta = acos(dot_prod/(len_old*len_new));   % The angle between two gradient vectors
                    
                    indicator_new = traj_map(r_new,c_new);
                    if indicator_new ~= 0                                       % If the new pixel was already reached before
                        if marker ~= indicator_new                              % If the already-reached trajectory is not equivalent to the current one
                            c_traj{indicator_new} = cat(1,c_traj{indicator_new},c_traj{marker}); % Assign the pixels in the current trajectory to the already-tracked trajectory
                            for i = 1:size(c_traj{marker},1)
                                traj_map(c_traj{marker}(i,1), c_traj{marker}(i,2)) = indicator_new;
                            end
                            c_traj{marker} = [];
                            marker = marker - 1;                                % Reset the current trajectory indicator for later use
                            valid_traj = 0;
                            break_cond = 1;                                     % Done!
                        else
                            sink(marker,1) = marker;
                            % If the already-reached trajectory is equivalent to the current one, we have a circular loop and hence no sink point.
                            % Note: But it may still be desirable to assign a sink point anyways. Need further testing.
                            % 130704: Assigns a sink point. Do not want NaN.
                            sink(marker,2) = r_old;
                            sink(marker,3) = c_old;
                            valid_traj = 1;
                        end
                    else
                        if theta > pi/2                     % Sink reached if more than 90 degrees turn in gradient vectors
                            sink(marker,1) = marker;        % The old point is the sink
                            sink(marker,2) = r_old;
                            sink(marker,3) = c_old;
                            valid_traj = 1;                 % Valid trajectory found
                        end
                    end
                end
                
                if valid_traj                               % If new trajectory candidate found
                    num_traj = nnz(traj_map == marker);     % Number of points belonging to the trajectory
                    
                    % This method is not really proper as it does not consider the possibility that later on, another trajectory might be found to have the same (or
                    % close-by) sink point. In that case those two trajectories ought to be merged and num_traj should be computed from the combined trajectory. However,
                    % implementing this would make things too complicated and most likely inefficient and just not worth it.
                    
                    if num_traj < min_n                     % If less than the minimum required (most likely noise)
                        traj_map(traj_map == marker) = 0;   % Destroy the current trajectory
                        c_traj{marker} = [];
                        sink(marker, 1) = NaN;
                        sink(marker, 2) = NaN;
                        sink(marker, 3) = NaN;
                        marker = marker - 1;
                    end 
                    break_cond = 1;
                end
                
                if break_cond
                    break;
                end
                
                r_old = r_new;  % With the new point as the current point, repeat the loop
                c_old = c_new;
            end
        end
    end
end

sink = sink(1:marker,:);        % Clean up unused spots
%% Region merging
sink_conv_dist = 3;     % Merge the trajectories only if their sink points are less than this distance away
max_int_diff = 0.1;      % Merge the trajectories only if their intensity levels differ by less than this amount

i = 1;
while i <= size(sink,1)     % Loop through all sink points
    r_cor = sink(i,2);      % Get the row, column coordinates
    c_cor = sink(i,3);
    identifier = sink(i,1); % Get the identifier
    
    if f(r_cor, c_cor) >= T     % If the sink belongs to a bright spot

        dist = [sink(:,1), sink(:,2) - r_cor, sink(:,3) - c_cor];
        dist(i,:) = []; % Remove the current sink under consideration

        dist = [dist(:,1), sqrt(dist(:,2).^2 + dist(:,3).^2)];  % Distances from the current sink point
        merge_candidates = dist(:,2) < sink_conv_dist;          % Get the candidates satisfying max distance

        merge_candidate_marks = dist(merge_candidates);         % Get the identifier of the candidates
        
        for j = merge_candidate_marks'    % For each candidate, check connectivity
            combined_map = (traj_map == identifier) + (traj_map == j);
            connectivity = bwconncomp(combined_map);
            
            i_can = find(sink(:,1) == j);
            r_can = sink(i_can, 2);
            c_can = sink(i_can, 3);
            
            connect_criteria = (connectivity.NumObjects == 1);  % Check for connectivity
            
            %int_diff = abs( f(r_cor, c_cor) - f(r_can, c_can) );
            %int_criteria = int_diff <= max_int_diff;     % Check for intensity difference

            if connect_criteria %&& int_criteria     % If both criteria are satisfied 
                traj_map(traj_map == j) = identifier;
                
                if find(sink(:,1) == j) <= i
                    i = i - 1;          % If previous point, pull back
                end
                
                sink(sink(:,1)==j,:) = [];  % Take out the merged sink point

                marker = marker - 1;    % Number of trajectories decreased by 1
            end
        end
    else                                        % If the sink belongs to background
        traj_map(traj_map == identifier) = 0;   % Destroy the trajectory
        sink(i,:) = [];
        marker = marker - 1;        % Number of trajectories decreased by 1
        i = i - 1;  % Since we just destroyed the ith trajectory
    end
    
    i = i + 1;
end

traj_map = uint16(traj_map);    % Convert to 16-bit

%% Convert sink points to centre points (i.e. centre of mass)

%for i = 1:size(sink,1)      % Loop through all sink points
%    mask = (traj_map == sink(i,1));
%    cp = regionprops(mask, 'Centroid'); % Extract centre point
%    sink(i,2) = round(cp.Centroid(2));     % Row (y) coordinate
%    sink(i,3) = round(cp.Centroid(1));     % Column (x) coordinate
%end