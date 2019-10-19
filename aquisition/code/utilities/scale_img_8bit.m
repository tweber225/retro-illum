function scaledImg8b = scale_img_8bit(img,calibImg,calibFlag,filterSigma)
% Function to perform a bit of light image processing for display
displayGamma = 1;

% Sum in double precision
sumImg = sum(img,4,'double');

% If calibration flag is true, divide by calibration to even out PRNU
if calibFlag == 1
    sumImg = sumImg./calibImg;
end

% Perform field flattening (to remove low spatial frequencies)
filtImg = sumImg./imgaussfilt(sumImg,filterSigma) - 1; % and also center around 0

% Perform bipolar gamma operation
signImg = sign(filtImg);
absGammaImg = abs(filtImg).^displayGamma;

maxAbsGamma = max(absGammaImg(:));
scaledGammaImg = absGammaImg./maxAbsGamma;

% Convert to 8 bit
scaledImg8b = uint8(128 + 127*scaledGammaImg.*signImg);