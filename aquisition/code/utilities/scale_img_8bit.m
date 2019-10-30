function scaledImg8b = scale_img_8bit(img,calibImg,filterSigma)
% Function to perform a bit of light image processing for display

% Sum in 16 bit, then convert to single (slightly fast than summing in
% single precision)
sumImg = single(sum(uint16(img),4,'native'));

% Divide by calibration to even out PRNU (both in single precision)
sumImg = sumImg./calibImg;

% Perform field flattening (to remove low spatial frequencies)
filtImg = sumImg./imgaussfilt(sumImg,filterSigma) - 1; % and also center around 0

% Perform bipolar gamma operation
signImg = sign(filtImg);
absGammaImg = abs(filtImg);

maxAbsGamma = max(absGammaImg(:));
scaledGammaImg = absGammaImg./maxAbsGamma;

% Convert to 8 bit
scaledImg8b = uint8(128 + 127*scaledGammaImg.*signImg);