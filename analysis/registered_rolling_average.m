function registered_rolling_average(captureDirectory)

% Add paths to enable calling subfunctions
thisFilePath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisFilePath = strjoin(thisFilePath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisFilePath)); % add subfolders

% Load analysis settings (makes a structure "analysisSettings")
analysis_settings;
MAOrd = analysisSettings.MAOrder; % Shorten this

% Load this stack's acquisition settings
acqSettings = load_settings(captureDirectory);
stackDims = [acqSettings.ySize,acqSettings.xSize,acqSettings.numCaptureFrames];
stackBitDepth = acqSettings.bitDepth;

% Load raw stack from binary
rawFilePath = [captureDirectory filesep 'raw.dat'];
rawStack = load_binary_stack(rawFilePath,stackDims,stackBitDepth);

% Allocate space for averaged frames
avgFrames = zeros(size(rawStack),'uint8');

% Check whether calibration file exists--load it if it does
if acqSettings.calibrationAcquired
    calibFileName = [captureDirectory filesep 'calibration.tif'];
    calibFrame = loadtiff(calibFileName);
else
    calibFrame = ones(acqSettings.ySize,acqSettings.xSize,'single');
end

% Compute cropping indices
xCrop = (acqSettings.xSize/2 - analysisSettings.regXCrop/2 + 1):(acqSettings.xSize/2 + analysisSettings.regXCrop/2);
yCrop = (acqSettings.ySize/2 - analysisSettings.regYCrop/2 + 1):(acqSettings.ySize/2 + analysisSettings.regYCrop/2);


if analysisSettings.useGPU
    % Because of the small size of GPU RAM, need to do processing in
    % N-frame "chunks"
    N = analysisSettings.MARegFramesPerChunk;
    NValid = N - 2*MAOrd;
    numChunks = ceil((acqSettings.numCaptureFrames-(2*MAOrd))/NValid);
    
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
        
        % Compute chunk FT on crop
        chunkFT = fft2(chunkSingle(yCrop,xCrop,:));

        % Compute 1st-Nth order frame registrations
        for regOrder = 1:MAOrd
            % for second term, shift 3rd dimension by order number
            xPowSpec = chunkFT.*circshift(conj(chunkFT),-regOrder,3); 

            % Normalize the cross power spectrum
            xPowSpec = xPowSpec./abs(xPowSpec);

            % IFFT2 back into real domain
            xCorrOrder = fftshift(fftshift(abs(ifft2(xPowSpec)),1),2);

            % Find peak of cross correlation
            [~,idxsX] = max(max(xCorrOrder,[],1),[],2);
            idxsX = squeeze(idxsX) - analysisSettings.regXCrop/2 -1;
            [~,idxsY] = max(max(xCorrOrder,[],2),[],1);
            idxsY = squeeze(idxsY) - analysisSettings.regYCrop/2 -1;

            
            % With shifts X and Y, circshift frames before and after selected frame
            for frIdx = (MAOrd+1):(numFrames-MAOrd)
                % Trailing frames
                shiftedTrailingFrame = circshift(chunkSingle(:,:,frIdx-regOrder),[-idxsY(frIdx-regOrder),-idxsX(frIdx-regOrder)]);
                avgFrameReg(:,:,frIdx-MAOrd) = avgFrameReg(:,:,frIdx-MAOrd) + shiftedTrailingFrame;
                % Leading frames
                shiftedLeadingFrame = circshift(chunkSingle(:,:,frIdx+regOrder),[idxsY(frIdx),idxsX(frIdx)]);
                avgFrameReg(:,:,frIdx-MAOrd) = avgFrameReg(:,:,frIdx-MAOrd) + shiftedLeadingFrame;
            end %end frame looping

        end % end particular order frame comparison/registration

        % Scale frames by their max
        avgFrameRegAbs = abs(avgFrameReg);
        maxEachFrame = max(avgFrameRegAbs,[],[1 2]); clear avgFrameRegAbs
        avgFrameReg = avgFrameReg./repmat(maxEachFrame,[acqSettings.ySize,acqSettings.xSize,1]);
        
        % convert to 8 bit
        avgFrameReg8bit = uint8(single(128) + single(127).*avgFrameReg);
        
        % Send back averaged frames to host
        avgFrames(:,:,fStartValid:fEndValid) = gather(avgFrameReg8bit);

    end % end chunk looping
    
else
    % To do: CPU implementation
end

toc

% Save the averaged frames
saveastiff(avgFrames,[captureDirectory filesep 'rolling_average.tif']);


