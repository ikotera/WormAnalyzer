classdef dataFormatter < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
    properties
        df________________;
        path;
        matBehav;
        nameMutant;
        nPoints;
        nWorms;
        nPhases;
        nBehaviors;
        listB =     {   'forward';
                        'reverse';
                        'turn';
                        'pause'};
                     
        listP  =    {   'preheat',     nan,    nan;              
                        'heat1',       nan,    nan;
                        'postheat1',   nan,    nan;
                        'heat2',       nan,    nan;
                        'postheat2',   nan,    nan;
                        'heat3',       nan,    nan;
                        'postheat3',   nan,    nan;
                        'heat4',       nan,    nan;
                        'postheat4',   nan,    nan;
                        'heat5',       nan,    nan;
                        'postheat5',   nan,    nan};

    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    methods (Access = public)
        function df = dataFormatter(path)
            
            df.nPhases = size(df.listP, 1);
            df.nBehaviors = size(df.listB, 1);
            
            if nargin == 1
                df.path = path;
                listFilesBeh = rdir(df.path);
            else
                df.path =  'E:\dataTemp\N2';
                listFilesBeh = rdir([df.path, '\**\behaviorsResampled*.mat']);
            end
            
            numFiles = numel(listFilesBeh);
            if numFiles < 1
                prt('No worm to analyze.');
                return
            end
            
            sB = load( listFilesBeh.name );
            df.matBehav = sB.bm.behaviors.resampled;
            [df.nPoints, df.nWorms] = size(df.matBehav);
            iSl = strfind(listFilesBeh.name, '\');
            df.nameMutant = listFilesBeh.name( iSl(end-1)+1:iSl(end)-1 );
        end
%=================================================================================================================================    
        function cm = cropMatrixBehavior(df, p)
            phase = p;
            [idxP, st, ed, phase] = getIndeces(df, phase);

            cm.matrix = df.matBehav(st:ed, :);
%             cm.behavior = behav;
%             cm.behaviorIndex = idxB;
            cm.phase = phase;
            cm.phaseIndex = idxP;
            cm.nameMutant = df.nameMutant;

        end
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    methods (Access = protected)
        
        function [idxP, st, ed, phase] = getIndeces(df, phase)
       
            ini = 210;
            dur = 250;
            ign = 0;
            for r = 1:11
                df.listP(r, 2:3) = {(ini + (r - 1) * dur) + 1, ini + r * dur - ign};
            end
%             prt(listP);
                     

%             if ischar(behav)
%                 idxB = find( strcmp(behav, df.listB) );
%             elseif isnumeric(behav)
%                 idxB = behav;
%                 behav = df.listB{behav};
%             else
%                 idxB = nan;
%             end
            
            if ischar(phase)
                idxP = find( strcmp(phase, df.listP) );
            elseif isnumeric(phase)
                idxP = phase;
                phase = df.listP{phase, 1};
            else
                idxP = nan;
            end
                     
            [st, ed] = df.listP{idxP, 2:3};

        end
    end
end

