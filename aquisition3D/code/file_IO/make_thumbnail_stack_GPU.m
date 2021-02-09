function stack8Bit = make_thumbnail_stack_GPU(rawStack,calibFrame,thumbnailOptions)
% thumbnailOptions argument should have fields
% .filterSigma
% .scaleDownFactor
% .xCropWidth
% .yCropWidth
% .maxGPUVarSize -- I suggest 1 GB here
scaleFactor = thumbnailOptions.scaleDownFactor;
xCropWidth = thumbnailOptions.xCropWidth;
yCropHeight = thumbnailOptions.yCropWidth;

% Calculate frame decimation factor
[yPix,xPix,numFrames] = size(rawStack);
cropFrameSize = xCropWidth*yCropHeight*4; % in single precision
frameDecimationFactor = ceil(numFrames/(thumbnailOptions.maxGPUVarSize/cropFrameSize));

% Derive indices into raw data
frameCrop = 1:frameDecimationFactor:numFrames;
numCroppedFrames = length(frameCrop);
xCrop = (xPix/2-xCropWidth/2+1):(xPix/2+xCropWidth/2);
yCrop = (yPix/2-yCropHeight/2+1):(yPix/2+yCropHeight/2);

% Resize calibration frame in GPU as single precision
resizedCalibGPU = imresize(single(gpuArray(calibFrame(yCrop,xCrop))),scaleFactor);

% Bring cropped and decimated stack into GPU and convert to single
% precision
floatStackGPU = single(gpuArray(rawStack(yCrop,xCrop,frameCrop))); % rawStack comes in as uint8

% Resize raw stack (do this in two rounds)
resizedX = ceil(scaleFactor*xCropWidth);
resizedY = ceil(scaleFactor*yCropHeight);
halfwayFrame = round(numCroppedFrames/2);
resizedStackGPU = zeros(resizedY,resizedX,numCroppedFrames,'single','gpuArray');
resizedStackGPU(:,:,1:halfwayFrame) = imresize(floatStackGPU(:,:,1:halfwayFrame),scaleFactor);
resizedStackGPU(:,:,(halfwayFrame+1):end) = imresize(floatStackGPU(:,:,(halfwayFrame+1):end),scaleFactor);
clear floatStack

% Apply calibration (to fix PRNU)
resizedStackGPU = resizedStackGPU./repmat(resizedCalibGPU,[1 1 numCroppedFrames]);

% Flatten field, subtract 1 to center signal around 0
resizedStackGPU = resizedStackGPU./imgaussfilt(resizedStackGPU,thumbnailOptions.filterSigma) - 1;

% Scale data
maxAbs = max(abs(resizedStackGPU),[],[1 2]); % max in dims 1 and 2
maxAbs = smooth(maxAbs); % so scaling doesn't change too rapidly
resizedStackGPU = resizedStackGPU./repmat(permute(maxAbs,[3 2 1]),[resizedY resizedX 1]);

% Convert to 8 bit and send back to host (from GPU)
stack8Bit = gather(uint8(127 + 128*resizedStackGPU));

