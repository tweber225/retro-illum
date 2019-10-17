function scaledImg8b = scale_img_8bit(img)
% Function to perform a bit of light image processing for display

% Sum in double precision
sumImg = sum(img,4,'double');

% Find min/max
minVal = min(sumImg(:));
maxVal = max(sumImg(:));
rangeVal = maxVal-minVal;

% Scale the image
scaledImg = (sumImg-minVal)./rangeVal;

% Convert to 8 bit
scaledImg8b = uint8(255*scaledImg);