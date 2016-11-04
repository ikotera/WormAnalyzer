function trackWorms(pathFile)

% flgTrack = true;

threshBin = 0.015;
threshArea = 5;
threshMinDist = 15;
threshMinTrack = 50;

% pathFile = 'C:\Ippei\141205-0022\Img-1_141205-0022.ice';
% pathFile = 'C:\Users\shakespeare\Desktop\141205-0022\Img-1_141205-0022.ice';


[pathFolder, nameFile, ~] = fileparts(pathFile);
nameMat = [pathFolder, '\', 'Tracks_', nameFile(7:end), '.mat'];

fid = fopen(pathFile, 'r');
Str = readHeaderICE(pathFile);
dimT = Str.dimT;
dimY = Str.dimY;
dimX = Str.dimX;

hFig = figure('Position', [10 10, 1024, 1024]);
hA = axes;

prepareImage(1);
maxImg = max(img(:));
minImg = min(img(:));
sizeImage = size(img);
centroids = cell(dimT, 1);
listArea = cell(dimT, 1);

hI = image(img, 'Parent', hA);
colormap(gray);
hP = line(0, 0, 'Marker', 'x', 'MarkerFaceColor', 'b', 'LineStyle', 'none', 'Parent', hA);

% if flgTrack

dirHome = getenv('USERPROFILE');
objWriter = VideoWriter([dirHome, '\Desktop\tracks.avi'], 'Uncompressed AVI');
objWriter.FrameRate = 25;
open(objWriter);

minDist = cell(dimT, 1);
minIdx = cell(dimT, 1);

% dimT = 10;

for fr = 1:dimT
    
    prepareImage(fr);
    
    [centroids{fr}, listArea{fr}, tophat] = findWorms(img, sizeImage, threshBin, threshArea);
    if fr > 1
        findClosestCentroid(fr);
    end
    
    set(hI, 'CData', tophat);
    
    if any(centroids{fr}(:, 1) ~= 0) && any(centroids{fr}(:, 2) ~= 0)
        set(hP, 'xdata', centroids{fr}(:, 1), 'ydata', centroids{fr}(:, 2));
        drawnow;
        F = getframe(hA);
        writeVideo(objWriter, F);
    end
    prt(fr);
end

save(nameMat,...
    'centroids', 'listArea', 'minDist', 'minIdx', 'threshBin', 'threshArea', 'threshMinDist');
    
% else
%     load('C:\Ippei\141205-0006\Tracks_141205-0006.mat');
% end




close(objWriter);



trax = [];

findTracks;

save(nameMat, 'trax', '-append');

for ln = 1:size(trax, 1)
    line(trax{ln}(:, 1), trax{ln}(:, 2), 'Color', [1 0 0], 'Parent', hA);
end


% prt('test');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function prepareImage(frame)
        img = loadICE(frame, 1, fid, dimX, dimY); % uint16
        if frame == 1
            maxImg = max(img(:));
            minImg = min(img(:));
        end
        img = scaleImage(img, maxImg, minImg); % uint8
    end

    function findClosestCentroid(frame)
        
        
        sizeCurr = size(centroids{frame}, 1);
        sizePrev = size(centroids{frame-1}, 1);
        
        xCurr = centroids{frame}(:, 1);
        yCurr = centroids{frame}(:, 2);
        xPrev = centroids{frame-1}(:, 1);
        yPrev = centroids{frame-1}(:, 2);        
        
        dist = nan(sizeCurr, sizePrev);
        
        for c = 1:sizeCurr
            for p = 1:sizePrev
            dist(c, p) = sqrt( ( xCurr(c) - xPrev(p) )^2 + ( yCurr(c) - yPrev(p) )^2 );
            end
        end
        
        [minDist{frame}, minIdx{frame}] = min(dist, [], 2);
%         minIdx = find(dist == minDist);
        
    end

    function findTracks
        
        idxNext = nan;
        for u = 1:dimT
            checkList{u, 1} = false(size(minDist{u})); %#ok<AGROW>
        end
        
        for frm = dimT:-1:1
            numWorms = size(minIdx{frm}, 1);
            for w = 1:numWorms
                
                track = nan(dimT, 2);
                for tr = frm:-1:2
                    %                     prt(frm, w, f, idxNext);
                    if tr == frm
                        if ~checkList{tr}(w)
%                             trax{end+1, 1} = nan(dimT, 2);
%                             trax{end, 1}(tr, :) = centroids{tr}(w, :);
                            track(tr, :) = centroids{tr}(w, :);
                            checkList{tr}(w) = true;
                            if minDist{tr}(w) > threshMinDist
                                break
                            end
                            idxNext = minIdx{tr}(w);
                        else
                            break
                        end
                    elseif ~checkList{tr}(idxNext)
%                         trax{end+1, 1} = nan(dimT, 2);
%                         trax{end, 1}(tr, :) = centroids{tr}(idxNext, :);
                        track(tr, :) = centroids{tr}(idxNext, :);
                        checkList{tr}(idxNext) = true;
                        if tr > 1
                            if minDist{tr}(idxNext) > threshMinDist
%                                 prt('break!', minDist{tr}(idxNext));
                                break
                            end
                            idxNext = minIdx{tr}(idxNext);
                            
                        end
                    else
                        break
                    end
                    
                end
                
                if dimT - sum( isnan(track(:, 1) ) ) >= threshMinTrack
%                     trax{end+1, 1} = nan(dimT, 2);
                    trax{end+1, 1} = track;
                    
                end
                
                
                
            end
        end
        
    end


end





