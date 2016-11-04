function [thetaVel, rhoVel] = computeVelocity(tracks, timeStamps, shift)


%% Calculation of Anatomical and Velocity Vecotrs


sizeTracks = size(tracks, 1);
% velocities = cell(sizeTracks, 1);



% Shift the time-series for displacement calculations
nanShift = NaN(shift, 1);

% Calculation of time displacement in numAvereage frames
timeStampsShifted = [nanShift;timeStamps(:)];
deltaT = timeStamps(1 + shift:end, 1) - timeStampsShifted(1 + shift:end - shift, 1);


for tr = 1:sizeTracks
    posX = tracks{tr}(:, 1);
    posY = tracks{tr}(:, 2);
    
    
    posXShifted = [nanShift;posX(:, 1)];
    posYShifted = [nanShift;posY(:, 1)];
    
    
    % Calculation of position displacement in numAverage frames
    deltaX = posX(1 + shift:end, 1) - posXShifted(1 + shift:end - shift, 1);
    deltaY = posY(1 + shift:end, 1) - posYShifted(1 + shift:end - shift, 1);
    
    
    % Calculation of average velocity in numAverage frames
    velX = deltaX ./ deltaT;
    velY = deltaY ./ deltaT;
    
    % Angles and norms of velocity vectors
    [thetaVel(:, tr), rhoVel(:, tr)]=cart2pol([velX;nanShift], [velY;nanShift]);
    
    
end


% Angles and norms of velocity vectors
% [thetaVel, rhoVel]=cart2pol([velX;shift], [velY;shift]);

% velX = cat( 2, velocities{:, 1}(1, 1) );
% velY = cat( 2, velocities{:, 1}(:, 2) );
% figure;plot(timeStamps, rhoVel)




end