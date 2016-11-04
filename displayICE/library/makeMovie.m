%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export Movie
    function makeMovie(dimT, dimZ, hDisplayImage, hAxis)
    
    dirHome = getenv('USERPROFILE');
    pathFile = [dirHome, '\Desktop\movie.avi'];
        
        objWriter = VideoWriter(pathFile, 'Uncompressed AVI');
        objWriter.FrameRate = 25;
        open(objWriter);
        
        for T = 1:dimT/dimZ
            % Update to the selected image
            hDisplayImage(T);

            F = getframe(hAxis);
            writeVideo(objWriter, F);
            prt('Frame = ', T);
        end
        
        close(objWriter);
        prt('Movie Saved as ', pathFile);
    end