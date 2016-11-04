function shiftedStack = shiftStack(stack, shiftY, shiftX)

shiftedStack = zeros(size(stack), 'uint16');

if shiftY >= 0 && shiftX >= 0
    shiftedStack(1+shiftY:end, 1+shiftX:end, :) = stack(1:end-shiftY, 1:end-shiftX, :);
elseif shiftY >= 0 && shiftX < 0
    shiftedStack(1+shiftY:end, 1:end+shiftX, :) = stack(1:end-shiftY, 1-shiftX:end, :);
elseif shiftY < 0 && shiftX >= 0
    shiftedStack(1:end+shiftY, 1+shiftX:end, :) = stack(1-shiftY:end, 1:end-shiftX, :);
else
    shiftedStack(1:end+shiftY, 1:end+shiftX, :) = stack(1-shiftY:end, 1-shiftX:end, :);
end