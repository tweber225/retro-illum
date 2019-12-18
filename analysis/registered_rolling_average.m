function registered_rolling_average(captureDirectory)


% Add paths to enable calling subfunctions
thisFilePath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisFilePath = strjoin(thisFilePath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisFilePath)); % add subfolders

% Load analysis settings (makes a structure "analysisSettings")
analysis_settings;
MAOrd = analysisSettings.MAOrder; % Shorten this
numFrameAvg = MAOrd*2 + 1;

% Check that the file doesn't exist
saveFileName = [captureDirectory filesep 'rolling_average_' num2str(numFrameAvg) 'frames.tif'];
if exist(saveFileName,'file')
    error('File already exists!')
end

% Load this stack's acquisition settings
acqSettings = load_settings(captureDirectory);
stackDims = [acqSettings.ySize,acqSettings.xSize,acqSettings.numCaptureFrames];
stackBitDepth = acqSettings.bitDepth;

% Load raw stack from binary
rawFilePath = [captureDirectory filesep 'raw.dat'];
rawStack = load_binary_stack(rawFilePath,stackDims,stackBitDepth);

% Allocate space for averaged frames
avgFrames = zeros(size(rawStack),'uint16');

% Check whether calibration file exists--load it if it does (recommended)
if acqSettings.calibrationAcquired
    calibFileName = [captureDirectory filesep 'calibration.tif'];
    calibFrame = loadtiff(calibFileName);
else % and if not just make an image of ones
    calibFrame = ones(acqSettings.ySize,acqSettings.xSize,'single');
end

% Compute cropping indices
xCrop = (acqSettings.xSize/2 - analysisSettings.regXCrop/2 + 1):(acqSettings.xSize/2 + analysisSettings.regXCrop/2);
yCrop = (acqSettings.ySize/2 - analysisSettings.regYCrop/2 + 1):(acqSettings.ySize/2 + analysisSettings.regYCrop/2);


% Because of the relatively small size of GPU RAM, need to do
% processing in N-frame "chunks"
N = analysisSettings.MARegFramesPerChunk;
NValid = N - 2*MAOrd;
numChunks = ceil((acqSettings.numCaptureFrames-(2*MAOrd))/NValid);

% Make bandpass filter for cross power spectrum
donutFiltGPU = make_donut_filt(analysisSettings.regYCrop,analysisSettings.regXCrop,analysisSettings.minRho,analysisSettings.maxRho);

for cIdx = 1:numChunks
    disp(['starting chunk ' num2str(cIdx)])
    % Calculate chunk start and end frames
    fStart = (cIdx-1)*NValid + 1 ;
    fEnd = min((cIdx-1)*NValid + N,acqSettings.numCaptureFrames);
    numFrames = fEnd-fStart+1;
    fStartValid = fStart+MAOrd;
    fEndValid = fEnd-MAOrd;
    validFrames = fEndValid-fStartValid+1;

    % Bring the data to GPU and convert to single-precision
    rawChunk = gpuArray(rawStack(:,:,fStart:fEnd));
    chunkSingle = single(rawChunk); clear rawChunk
    calibFrameGPU = gpuArray(calibFrame);

    % Correct PRNU 
    chunkSingle = chunkSingle./repmat(calibFrameGPU,[1 1 (fEnd-fStart+1)]);

    % Flatten field and subtract 1 to center data around 0
    chunkSingle = chunkSingle./imgaussfilt(chunkSingle,analysisSettings.flatSigma) - 1;

    % Allocate space for rolling average and place flattened frames into each
    avgFrameReg = chunkSingle(:,:,(MAOrd+1):(MAOrd+validFrames));

    % Compute chunk FT on cropped image set
    chunkFT = fft2(chunkSingle(yCrop,xCrop,:));

    % Compute 1st-Nth order frame registrations
    % 1st order means between frames and their 1st neighbor, etc
    for regOrder = 1:MAOrd
        % for second term, shift 3rd dimension by order number
        xPowSpec = chunkFT.*circshift(conj(chunkFT),-regOrder,3); 

        % Filter out of band frequencies with donut filter
        xPowSpec = xPowSpec.*donutFiltGPU; % use arrayfun here?

        % IFFT2 back into real domain
        xCorrOrder = abs(ifft2(xPowSpec));

        % Set 1,1 to 0 to avoid the static component
        xCorrOrder(1,1,:) = 0;
        
        % Set overly-large shifts to 0
        maxShiftThisOrder = MAOrd*analysisSettings.maxShiftPerFrame;
        xCorrOrder((1+maxShiftThisOrder):(analysisSettings.regYCrop-maxShiftThisOrder),:,:) = 0;
        xCorrOrder(:,(1+maxShiftThisOrder):(analysisSettings.regXCrop-maxShiftThisOrder),:) = 0;
        
        % Find peak of cross correlation
        [~,idxsX] = max(max(xCorrOrder,[],1),[],2);
        [~,idxsY] = max(max(xCorrOrder,[],2),[],1);
        clear xCorrOrder
        shiftsX = arrayfun(@idx_to_real_shift,squeeze(idxsX),analysisSettings.regXCrop);
        shiftsY = arrayfun(@idx_to_real_shift,squeeze(idxsY),analysisSettings.regYCrop);

        % With shifts X and Y, circshift frames before and after selected frame
        for frIdx = (MAOrd+1):(numFrames-MAOrd)
            % Trailing (before) frames
            shiftedTrailingFrame = circshift(chunkSingle(:,:,frIdx-regOrder),[-shiftsY(frIdx-regOrder),-shiftsX(frIdx-regOrder)]);
            avgFrameReg(:,:,frIdx-MAOrd) = avgFrameReg(:,:,frIdx-MAOrd) + shiftedTrailingFrame;
            % Leading (after) frames
            shiftedLeadingFrame = circshift(chunkSingle(:,:,frIdx+regOrder),[shiftsY(frIdx),shiftsX(frIdx)]);
            avgFrameReg(:,:,frIdx-MAOrd) = avgFrameReg(:,:,frIdx-MAOrd) + shiftedLeadingFrame;
        end %end frame looping

    end % end particular order frame comparison/registration

    % Scale range [-1,1] to fill uint16 [0,65535]
    avgFrameReg16bit = arrayfun(@scale_avg_frame_to_uint16,avgFrameReg,numFrameAvg);
    
    % Send back averaged frames to host
    avgFrames(:,:,fStartValid:fEndValid) = gather(avgFrameReg16bit);

end % end chunk looping
    

% Display processing time
disp(['Processing time: ' num2str(toc) ' sec']);

% Save the averaged frames
avgFrames = avgFrames(:,:,1:analysisSettings.decimationFactor:end); % decimates frames a bit
saveastiff(avgFrames,saveFileName);


