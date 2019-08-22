function scaledImg = scale_img_8bit(img)


% Find min/max
minVal = min(img(:));
maxVal = max(img(:));
rangeVal = single(maxVal-minVal);

% Scale the image
scaledImg = uint8(((single(img-minVal))./rangeVal)*255);