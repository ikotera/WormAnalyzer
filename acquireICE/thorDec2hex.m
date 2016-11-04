function hex = thorDec2hex(dec, bytesHex)

% Converts numerical value to hex values to be sent to Thorlabs stage via RS-232
if dec < 0
    % Two's complement for negative numbers
    hex = reshape(fliplr(reshape(dec2hex(16^bytesHex + dec, bytesHex), 2, bytesHex/2)), 1, bytesHex);
else
    hex = reshape(fliplr(reshape(dec2hex(dec, bytesHex), 2, bytesHex/2)), 1, bytesHex);
end

end