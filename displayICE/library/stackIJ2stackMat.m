function stack = stackIJ2stackMat(stackIJ, dimX, dimY, dimZ)  
% stack = stackIJ2stackMat(stackIJ, dimX, dimY, dimZ)
% Bring back the ImageJ's image stack (ij.ImageStack) to MATLAB

    ist = stackIJ.getStack();
    stack = nan(dimX, dimY, dimZ);
    for z = 1:dimZ
        sp = ist.getProcessor(z);
        fp = sp.getPixels();
        stack(:, :, z) = flipud(rot90(reshape(fp, dimX, dimY), 1));
    end
    
end