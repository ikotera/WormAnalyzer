function shiftedImage = shiftImageSubpixel(image, shiftY, shiftX)

[M, N] = size(image); %Assuming square matrix.
% M = gpuArray(M);
% N = gpuArray(N);
[xx, yy] = meshgrid(1:N,1:M); %xx,yy are both outputs of meshgrid (so called plaid matrices).
shiftedImage = interp2(xx, yy, (image), xx-shiftX, yy-shiftY);

end

