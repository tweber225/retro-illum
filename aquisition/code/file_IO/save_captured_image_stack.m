function save_captured_image_stack(captureStack,backgroundImg,saveDirectory)
filtSigma = 50;
scaleDownFactor = 0.75;
numFrames = size(captureStack,3);

%% Save the raw stack as .MAT file (binary)
% (raw data isn't really viewable anyway so skipping tiff format is ok)
capturePath = [saveDirectory filesep 'raw.mat'];
save(capturePath,'captureStack');

%% If background is not all 0's, save background file in single precision
% (this might be useful to have in tiff format)
if sum(backgroundImg(:).^2) ~= 0
    backgroundPath = [saveDirectory filesep 'background.tif'];
    saveastiff(single(backgroundImg),backgroundPath);
end

%% Save "thumbnail" version of the stack (PRNU-corrected and flattened)
flattenedStack = zeros(size(captureStack),'uint8');

% Loop through frames
for frameIdx = 1:numFrames
    % Display progress
    %disp(['Processing frame ' num2str(frameIdx) ' of ' num2str(numFrames)])
    
    % Select frame
    thisFrame = double(captureStack(:,:,frameIdx));
    
    % Correct PRNU
    correctedFrame = thisFrame./backgroundImg;
    
    % Flatten field
    flatFrame = correctedFrame./imgaussfilt(correctedFrame,filtSigma) - 1;
    
    % Scale data
    signImg = sign(flatFrame);
    absImg = abs(flatFrame);
    maxAbs = max(absImg(:));
    scaledImg = absImg./maxAbs;
    
    % Give back sign and resize
    resizedImg = imresize(scaledImg.*signImg,scaleDownFactor,'bilinear');
    
    % Convert to 8 bit
    scaledImg8b = uint8(128 + 127*resizedImg);
    
    % Put into array
    flattenedStack(:,:,frameIdx) = scaledImg8b;
    
end

% Then save the flattened stack
saveFileName = [saveDirectory filesep 'flattened.tif'];
saveastiff(flattenedStack,saveFileName);
