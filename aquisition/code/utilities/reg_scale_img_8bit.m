function scaledImg8b = reg_scale_img_8bit(imgGPU,calibImgGPU,filterSigma)
% Function to perform image registration, averaging and field flattening.
% imgGPU, calibImgGPU should already be on the GPU, ie of class gpuArray
% This is the more advanced variant of "scale_img_8bit" which simply sums
% down the time dimension

numFrames = single(size(imgGPU,4));
middleFrame = ceil(numFrames/2);

% Convert image stream to single, divide out by calibration to even PRNU
correctedImg = arrayfun(@single_div_calib,imgGPU,calibImgGPU);

% Registration step 1: FT
imgFT = fft2(correctedImg);

% step 2: Cross power spectrum-referenced to middle frame of stream
xPowSpec = conj(imgFT(:,:,:,middleFrame)).*imgFT;

% Step 3: inverse FT to make cross correlations
xCorrs = abs(ifft2(xPowSpec));

% Step 4: set 1,1 to 0 to avoid static component
%xCorrs(1,1,:,:) = 0;

% Step 5: Locate peaks
[~,xPkIdx] = max(max(xCorrs,[],1),[],2);
[~,yPkIdx] = max(max(xCorrs,[],2),[],1);

% Step 6: Shift each frame and sum in single precision
sumImg = correctedImg(:,:,:,1); % store first (template frame)
for fIdx = 1:numFrames
    if fIdx == middleFrame
        continue
    end
    sumImg = sumImg + circshift(correctedImg(:,:,:,fIdx),[-yPkIdx(fIdx)+1,-xPkIdx(fIdx)+1]);
end

% Perform field flattening (to remove low spatial frequencies)
filtImg = arrayfun(@flatten_field,sumImg,imgaussfilt(sumImg,filterSigma));

% Perform scaling operation
absImg = abs(filtImg);
maxAbs = max(absImg(:));
scaledImg = filtImg./maxAbs;

% Convert to 8 bit and bring back to host
scaledImg8b = gather(arrayfun(@scale_single_to_uint8,scaledImg));

