function processWriteToDisk(depthBit, dimX, dimY)

dbstop if error;
% dbstop in processWriteToDisk 6;

waitProc = 0.3;

SM = [];
s.depthBit = depthBit;
s.dimX = dimX;
s.dimY = dimY;
s = prepareSharedMemory(s);
SM = createSharedMemory(SM, 'memBuffer.dat', s.iniMat, s.format, s.formatFile);

% SM.Data.readySlave = 1;

while true
%     sleep(waitProc);
    if SM.Data.readyMaster == 1 && SM.Data.readySlave == 0
        hc = readCharInSharedMemory(SM, 'headerChar');
        nf = readCharInSharedMemory(SM, 'nameFile');
        fid = writeICE(nan, nan, nf, SM.Data.headerNum, hc);
        sizeCb = s.sizeBuffer;
%         vector = zeros(s.sizeImage * 10, 1, 'uint16');
        cb = 1;
        fr = 1;
%         ii = 0;
        SM.Data.readySlave = 1;
    elseif SM.Data.readyMaster == 1 && SM.Data.readySlave == 1
        if fr < SM.Data.frame
            writeToDisk;
        else
            pause(0.001);
        end
%         pause(0.00001);
    elseif SM.Data.readyMaster == 0 && SM.Data.readySlave ==1
        if fr <= SM.Data.frame
            writeToDisk;
%             if (SM.Data.frame == fr)  % Last frame
%                 pause(0.5);
%                 writeToDisk;
%             end
        else
            fclose(fid);
            SM.Data.readySlave = 0;
        end
    else
        pause(waitProc);
    end
    
    if SM.Data.destroySlave == 1
        exitProcess;
    end
end

    function writeToDisk
        
%         if ii < 10
%             vector( s.sizeImage * ii + 1:s.sizeImage * (ii + 1) ) = SM.Data.image(:, cb);
%             ii = ii + 1;
%         else
            t = tic;
            fwrite(fid, SM.Data.image(:, cb), ['uint', num2str(depthBit)]);
            prt('%0.4f', cb, fr, SM.Data.frame, toc(t) );
%             vector = zeros(s.sizeImage * 10, 1, 'uint16');
%             ii = 0;
%         end
        
        cb = cb + 1;
        fr = fr + 1;
        if cb > sizeCb
            cb = 1;
        end
    end

    function exitProcess
        fclose all;
        SM.Data.destroySlave = 0;
        SM.Data.readySlave = 0;
        SM.Data.frame = 1;
        clear SM;
        exit;
    end



end