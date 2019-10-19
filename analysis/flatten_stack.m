function flatten_stack(captureDirectory)
filtGamma = 50;

% Add paths
userPathSplit = regexp(userpath,filesep,'split');   
addpath(genpath(fullfile(userPathSplit{1},userPathSplit{2},userPathSplit{3},'retro-illum','analysis')));

% Check whether background exists
backgroundFileName = [captureDirectory filesep 'background.tif'];
if exist(backgroundFileName,'file')
    backgroundFrame = loadtiff(backgroundFileName);
else
    backgroundFrame = 1;
end

% Load the raw data
rawFileName = [captureDirectory filesep 'raw.tif'];
rawStack = loadtiff(rawFileName);
numFrames = size(rawStack,3);

% Make new array
flattenedStack = zeros(size(rawStack),'uint8');

% Loop through frames
for frameIdx = 1:numFrames
    % Display progress
    disp(['Processing frame ' num2str(frameIdx) ' of ' num2str(numFrames)])
    
    % Select frame
    thisFrame = double(rawStack(:,:,frameIdx));
    
    % Correct PRNU
    correctedFrame = thisFrame./backgroundFrame;
    
    % Flatten field
    flatFrame = correctedFrame./imgaussfilt(correctedFrame,filtGamma) - 1;
    
    % Scale data
    signImg = sign(flatFrame);
    absImg = abs(flatFrame);
    maxAbs = max(absImg(:));
    scaledImg = absImg./maxAbs;
    
    % Convert to 8 bit
    scaledImg8b = uint8(128 + 127*scaledImg.*signImg);
    
    % Put into array
    flattenedStack(:,:,frameIdx) = scaledImg8b;
    
end

% Then save the flattened stack
saveFileName = [captureDirectory filesep 'flattened.tif'];
saveastiff(flattenedStack,saveFileName);


