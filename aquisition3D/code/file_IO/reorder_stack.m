function stack = reorder_stack(stack,numFramesPerVol)
% Input stack must be 3D

% Find min in the first set of frames
meanStack = mean(stack(:,:,1:numFramesPerVol),[1 2]);
[~,minIdx] = min(meanStack(:));

% Shift whole stack up, drop the last set of frames
stack = circshift(stack,[0 0 -minIdx]);
stack = stack(:,:,1:end-numFramesPerVol);

% Split into volumes
stack = reshape(stack,[size(stack,1),size(stack,2),numFramesPerVol/2,size(stack,3)*2/numFramesPerVol]);

% Flip the even-numbered volumes
stack(:,:,:,2:2:end) = flip(stack(:,:,:,2:2:end),3);

% Reshape back into big tiff stack
stack = reshape(stack,[size(stack,1),size(stack,2),size(stack,3)*size(stack,4)]);