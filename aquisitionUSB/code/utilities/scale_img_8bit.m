function scaledImg8b = scale_img_8bit(imgGPU,calibImgGPU,filterSigma)
% Function to perform a bit of light image processing for display
% imgGPU, calibImgGPU should already be on the GPU, ie of class gpuArray

% Sum in 16 bit, then convert to single (slightly fast than summing in
% single precision)
sumImg = single(sum(uint16(imgGPU),4,'native'));

% Divide by calibration to even out PRNU (both in single precision)
sumImg = sumImg./calibImgGPU;

% Perform field flattening (to remove low spatial frequencies)
%filtImg = sumImg./imgaussfilt(sumImg,filterSigma) - 1; % and also center around 0
filtImg = arrayfun(@flatten_field,sumImg,imgaussfilt(sumImg,filterSigma));

% Perform scaling operation
absImg = abs(filtImg);
maxAbs = max(absImg(:));
scaledImg = filtImg./maxAbs;

% Convert to 8 bit
scaledImg8b = arrayfun(@scale_single_to_uint8,scaledImg);