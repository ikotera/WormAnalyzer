function imgOut = scaleImage(imgIn, maxIntensity, minIntensity)

% Convert the class of max/min values to match the input image class
cl = class(imgIn);
% maxIntensity = double(maxIntensity);
% minIntensity = double(minIntensity);

switch cl
    case {'uint16', 'int16', 'uint8'}
%         eval(['maxIntensity=', cl, '(maxIntensity);']);
%         eval(['minIntensity=', cl, '(minIntensity);']);
        
        % Scaling
        imgOut = uint8(   ( (imgIn - minIntensity) )  /  ( (maxIntensity - minIntensity) / (2^8-1))   );
%     case {'uint8', 'int8'}
%         imgOut = imgIn;
    otherwise
        error('Image class not supported');
end

end