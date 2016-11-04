classdef bcecfManager < abstractManager
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        listVar;
        listRoi;
        numVar;
        numRoi;
        vars;
        modeHeater;
        numTimepoints;
        sampling;
        bcecfL;
        bcecfH;
        time;
        temperature;
        tempTime;
        intensitiesL;
        intensitiesH;
        rsTime;
        normalizedRatioZap;
        statsZap;
        statsTec;
        statsTemp;
        ratioZap;
        ratioTec;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function bm = bcecfManager(pathFolder)
            bm = bm@abstractManager();
            
            b = bm.readFiles(pathFolder, 'Variables*.mat'); if ~b, return, end
            bm.listVar = bm.listFiles;
            bm.numVar = bm.numFiles;
            
            b = bm.readFiles(pathFolder, 'ROI.mat'); if ~b, return, end
            bm.listRoi = bm.listFiles;
            bm.numRoi = bm.numFiles;
            
            if bm.numVar ~= bm.numRoi, error('Missing Variables*.mat or ROI.mat'); end
            
            loadVar(bm);
            loadRoi(bm);
            resampleTs(bm);

        end
%=================================================================================================================================
        function loadRoi(bm)
            
            for f = 1:bm.numRoi
                s = load(bm.listRoi(f).name);
                bm.bcecfL{f} = s.intensityMean(:, :, 1);
                bm.bcecfH{f} = s.intensityMean(:, :, 2);
                bm.time{f} = s.timeElapsed;
            end

        end
%=================================================================================================================================
        function loadVar(bm)
            for f = 1:bm.numVar
                bm.vars{f} = load(bm.listVar(f).name);
            end
            bm.modeHeater = bm.vars{1}.modeHeater;
        end
%=================================================================================================================================
        function resampleTs(bm)
            warning('off', 'MATLAB:linearinter:noextrap');
            switch bm.modeHeater
                case 'TEC'
                    bm.numTimepoints = 250;
                    bm.sampling = 1;
                    
                    for f = 1:bm.numFiles
                        temp = bm.vars{f}.tempDaq;
                        tsT = timeseries(temp(:, 1), temp(:, 2), 'Name', 'temperature');
                        rsT  = resample(tsT, (1:bm.numTimepoints), 'linear');
                        bm.temperature(:, f) = rsT.Data;
                        bm.tempTime(:, f) = rsT.Time;
%                         figure; plot( temp(:, 1) );
                                               
                        tsL = timeseries(bm.bcecfL{f}, bm.time{f}, 'Name', 'bcecfL');
                        tsH = timeseries(bm.bcecfH{f}, bm.time{f}, 'Name', 'bcecfH');
                        rsL  = resample(tsL, (1:bm.numTimepoints/bm.sampling)*bm.sampling, 'linear');
                        rsH  = resample(tsH, (1:bm.numTimepoints/bm.sampling)*bm.sampling, 'linear');
                        bm.intensitiesL(:, f) = rsL.Data;
                        bm.intensitiesH(:, f) = rsH.Data;
                        bm.ratioTec(:, f) = bm.intensitiesH(:, f) ./ bm.intensitiesL(:, f);
                        bm.rsTime(:, f) = rsH.Time;
                        
                        mn = mean( bm.ratioTec(:, f), 'omitnan' );
                        bm.ratioTec(:, f) = bm.ratioTec(:, f) - mn;
%                         figure; plot( bm.ratioTec(:, f) );
                    end
                    
                    st = bm.getStats(bm.temperature);
                    bm.statsTemp = st;
                    figure; errorbarShade(bm.tempTime(:, 1), st.mean, st.ci99);                   
                    
                    st = bm.getStats(bm.ratioTec);
                    m = st.mean( ~isnan(st.mean) );
                    st.mean = st.mean - m(1);
                    figure; errorbarShade(bm.rsTime(:, 1), st.mean, st.ci99);
                    bm.statsTec = st;
                    
                    nonnan = all( [~isnan(bm.statsTemp.mean), ~isnan(bm.statsTec.mean)], 2 );
                    ft = fit(bm.statsTemp.mean(nonnan), bm.statsTec.mean(nonnan), 'poly1');
                    figure; plot(ft, bm.statsTemp.mean, bm.statsTec.mean);
                    ax = gca; ax.YLabel = []; ax.XLabel = [];
                    
                case 'zap'
                    bm.numTimepoints = 50;
                    bm.sampling = 0.001;

                    bm.intensitiesL = nan(bm.numTimepoints/bm.sampling, bm.numFiles);
                    bm.intensitiesH = nan(bm.numTimepoints/bm.sampling, bm.numFiles);
                    bm.normalizedRatioZap = nan(bm.numTimepoints/bm.sampling, bm.numFiles);
                    % Create time series object
                    for f = 1:bm.numFiles
                        tsL = timeseries(bm.bcecfL{f}, bm.time{f}, 'Name', 'bcecfL');
                        tsH = timeseries(bm.bcecfH{f}, bm.time{f}, 'Name', 'bcecfH');
                        rsL  = resample(tsL, (1:bm.numTimepoints/bm.sampling)*bm.sampling, 'linear');
                        rsH  = resample(tsH, (1:bm.numTimepoints/bm.sampling)*bm.sampling, 'linear');
                        bm.intensitiesL(:, f) = rsL.Data;
                        bm.intensitiesH(:, f) = rsH.Data;
                        bm.ratioZap(:, f) = bm.intensitiesH(:, f) ./ bm.intensitiesL(:, f);
                        
                        y = bm.ratioZap(:, f);
                        ny = y;
                        ny(1:8000, :) = nan;
                        ny(30000:end, :) = nan;
                        ny(9950:12000, :) = nan;
                        ny(14950:17000, :) = nan;
                        ny(19950:22000, :) = nan;
                        ny(24950:27000, :) = nan;
                        
                        x = (1:50000)';
                        nx = x( ~isnan(ny) );
                        
                        ny = y( ~isnan(ny) );
                        
                        ft = fit(nx, ny, 'fourier1');
                        bm.normalizedRatioZap(:, f) = y - ft(x);
                        
                        figure('Position', [100 100 300 500]);
                        subplot(2, 1, 1); plot(ft, x, y); legend('hide'); xlim([8000 30000]);
                        ax = gca; ax.XTickLabel = {'10', '15', '20', '25', '30'}; ax.YLabel = []; ax.XLabel = [];
                        subplot(2, 1, 2); plot( bm.normalizedRatioZap(:, f) ); xlim([8000 30000]);
                        ax = gca; ax.XTickLabel = {'10', '15', '20', '25', '30'};
                    end
                    
                    bm.rsTime = rsH.Time;
                    
                    
                    it = bm.normalizedRatioZap(8000:30000, :);
                    tm = bm.rsTime(8000:30000, :);
                    st = bm.getStats(it);

                    figure; errorbarShade(tm, st.mean, st.ci99); xlim([8 30]);
                    bm.statsZap = st;
                    
            end
            warning('on', 'MATLAB:linearinter:noextrap');
        end
        
        function stats = getStats(~, matrix)
            stats.mean = mean(matrix, 2);
            stats.sd = std(matrix, 0, 2);
            stats.se = stats.sd ./ sqrt( size(matrix, 2) );
            stats.ci99 = stats.se * 2.58;
        end

    end
    


    
end