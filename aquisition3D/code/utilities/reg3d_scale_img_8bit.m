function scaledImg8b = reg3d_scale_img_8bit(imgGPU,calibImgGPU,xPowFilt,filterSigma,framesPerVol,displayFrame)
% Function to perform image registration, averaging and field flattening.
% imgGPU, xPowFilt, calibImgGPU should already be on the GPU, ie of class gpuArray
% This is the more advanced variant of "scale_img_8bit" which simply sums
% down the time dimension

% Convert raw image stream to single, divide out by calibration to even PRNU
correctedImg = arrayfun(@single_div_calib,imgGPU,calibImgGPU);
numFrames = single(size(correctedImg,4));

% Shift frames to find "dark frame" in stack
avgFrameSignal = sum(correctedImg,[1 2]);
%avgFrameSignal = max(correctedImg,[],[1 2]);
[~,darkFrameIdx] = min(avgFrameSignal(:));
correctedImg = circshift(correctedImg,[0 0 0 -darkFrameIdx]);

if randn > 0
    correctedImg = correctedImg(:,:,:,displayFrame);
else
    correctedImg = correctedImg(:,:,:,mod(-displayFrame,framesPerVol)+1);
end
numFrames = 1;middleFrame = 1;
%disp(mean(gather(correctedImg),'all'))

% Registration step 1: FT
imgFT = fft2(correctedImg);

% Step 2: Cross power spectrum-referenced to middle frame of stream
xPowSpec = conj(imgFT(:,:,:,middleFrame)).*imgFT;
%xPowSpec = xPowSpec./abs(xPowSpec); % normalize

% Step 3: inverse FT to make cross correlations
xCorrs = real(ifft2(xPowSpec.*xPowFilt));

% Step 4: set 1,1 to 0 to avoid static component, also limit possible range
%xCorrs(1,1,:,:) = 0;
%xCorrs(65:704,:,:,:) = 0;
%xCorrs(:,65:704,:,:) = 0;

% Step 5: Locate peaks
[~,xPkIdx] = max(max(xCorrs,[],1),[],2);
[~,yPkIdx] = max(max(xCorrs,[],2),[],1);

% Step 6: Shift each frame and sum in single precision
sumImg = correctedImg(:,:,:,middleFrame); % store middle frame, which was the template
for fIdx = 1:numFrames
    if fIdx == middleFrame
        continue
    end
    sumImg = sumImg + circshift(correctedImg(:,:,:,fIdx),0*[-yPkIdx(fIdx)+1,-xPkIdx(fIdx)+1]);
end

% Perform field flattening (to remove low spatial frequencies)
filtImg = arrayfun(@flatten_field,sumImg,imgaussfilt(sumImg,filterSigma));

% Perform scaling operation
absImg = abs(filtImg);
maxAbs = max(absImg(:));
scaledImg = filtImg./maxAbs;scaledImg = filtImg./1;


% Convert to 8 bit and bring back to host
scaledImg8b = gather(arrayfun(@scale_single_to_uint8,scaledImg));

