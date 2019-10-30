function flatten_stack(captureDirectory)

% Add paths to enable calling subfunctions
thisFilePath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisFilePath = strjoin(thisFilePath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisFilePath)); % add subfolders

% Load analysis settings (makes a structure "analysisSettings")
analysis_settings;

% Load this stack's acquisition settings
acqSettings = load_settings(captureDirectory);
stackDims = [acqSettings.ySize,acqSettings.xSize,acqSettings.numCaptureFrames];
stackBitDepth = acqSettings.bitDepth;

% Load raw stack from binary
rawFilePath = [captureDirectory filesep 'raw.dat'];
rawStack = load_binary_stack(rawFilePath,stackDims,stackBitDepth);

% Check whether calibration file exists--load it if it does
if acqSettings.calibrationAcquired
    calibFileName = [captureDirectory filesep 'calibration.tif'];
    calibFrame = loadtiff(calibFileName);
else
    calibFrame = ones(acqSettings.ySize,acqSettings.xSize,'single');
end


tic
% Change behavior if GPU-enabled
if analysisSettings.useGPU
    % GPUs usually don't have enough memory for ~1024 single-prec frames,
    % so we need to do this N-frame chunks.
    N = round(analysisSettings.targetGPUMemSize/(4*acqSettings.ySize*acqSettings.xSize));
    numChunks = ceil(acqSettings.numCaptureFrames/N);
    
    % Make host array for incoming flattened data
    flattenedStack = zeros(acqSettings.ySize,acqSettings.xSize,acqSettings.numCaptureFrames,'uint8');

    % Loop through chunks
    for cIdx = 1:numChunks
        disp(['starting chunk ' num2str(cIdx)])
        % Calculate chunk start and end frames
        fStart = (cIdx-1)*N + 1;
        fEnd = min(cIdx*N,acqSettings.numCaptureFrames);
        
        % Bring the data to GPU and convert to single-precision
        rawChunk = gpuArray(rawStack(:,:,fStart:fEnd));
        chunkSingle = single(rawChunk); clear rawChunk
        calibFrameGPU = gpuArray(calibFrame);
        
        % Correct PRNU 
        chunkSingle = chunkSingle./repmat(calibFrameGPU,[1 1 (fEnd-fStart+1)]);
        
        % Flatten field and subtract 1 to center data around 0
        chunkSingle = chunkSingle./imgaussfilt(chunkSingle,analysisSettings.flatSigma) - 1;
        
        % Scale data
        absChunk = abs(chunkSingle);
        maxEachFrame = max(absChunk,[],[1 2]); clear absChunk
        maxEachFrame = smooth(maxEachFrame,analysisSettings.maxSmoothingSpan);
        maxEachFrame = permute(maxEachFrame,[2 3 1]);
        chunkSingle = chunkSingle./repmat(maxEachFrame,[acqSettings.ySize,acqSettings.xSize,1]);
        
        % Convert to 8-bit scale
        chunk8bit = uint8(single(128) + single(127).*chunkSingle);
        
        % Send back to host computer
        flattenedStack(:,:,fStart:fEnd) = gather(chunk8bit);
        
    end
    
else
    % On the CPU, if enough memory is available, we can avoid doing
    % flattening on chunks of frames and do it all at once
    
    % Convert to single precision
    singleStack = single(rawStack);
    
    % Correct PRNU
    singleStack = singleStack./calibFrame;
    
    % Flatten field
    singleStack = singleStack./imgaussfilt(singleStack,analysisSettings.flatSigma) - 1;

    % Scale data
    absStack = abs(singleStack);
    maxEachFrame = max(absStack,[],[1 2]); clear absStack
    maxEachFrame = smooth(maxEachFrame,analysisSettings.maxSmoothingSpan);
    maxEachFrame = permute(maxEachFrame,[2 3 1]);
    singleStack = singleStack./maxEachFrame;

    % Convert to 8 bit
    flattenedStack = uint8(127*singleStack + 128);
   
end



% Then save the flattened stack
saveFileName = [captureDirectory filesep 'flattened.tif'];
size(flattenedStack)
%saveastiff(flattenedStack,saveFileName);
toc

