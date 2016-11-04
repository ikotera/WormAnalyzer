function psf = generatePSF(dimX, dimY, dimZ, sigmaFocus, sigmaDefocus)
% psf = generatePSF(dimX, dimY, dimZ, sigmaFocus, sigmaDefocus);
%
% The function generates PSF by Gaussian method.

if ~exist('dimX', 'var'), dimX = 512; end
if ~exist('dimY', 'var'), dimY = 512; end
if ~exist('dimZ', 'var'), dimZ = 12; end
if ~exist('sigmaFocus', 'var'), sigmaFocus = 2; end
if ~exist('sigmaDefocus', 'var'), sigmaDefocus = 10; end

x0 = (dimX - 1) / 2;
y0 = (dimY - 1) / 2;
z0 = (dimZ - 1) / 2;

sigmaDelta = (sigmaDefocus - sigmaFocus) / z0;

psf = nan(dimX, dimY, dimZ);

for z = 0:dimZ - 1
    sigma = sigmaFocus + abs(z - z0) * sigmaDelta;
    for y = 0:dimY - 1
        for x = 0:dimX - 1
            psf(x+1, y+1, z+1) = exp( -( (x - x0)^2 + (y - y0)^2 ) / (2 * sigma^2) ) / (sigma^2);
        end
    end
end

psf = psf .* ( 1 / max(psf(:)) );

