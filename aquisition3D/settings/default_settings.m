% Default settings and notes on usage

% Camera SN
acqSettings.cameraSerialNumber = '23187241';

% Save data directory
acqSettings.dataPath = 'C:\Users\MertzLabAdmin\data';

% Camera configuration directory
acqSettings.saperaConfigFilePath = 'C:\Users\MertzLabAdmin\Documents\GitHub\retro-illum\cam configs\B_acA2040-180kmNIR_10tap8bit_fullarea.cca';

% Note session start time
acqSettings.sessionStartTime = datestr(datetime);
acqSettings.captureStartTime = 'none';

% Image Acquisition Toolbox Adapter name
acqSettings.adapterName = 'dalsa';

% Image size / ROI
acqSettings.centerX = true;
acqSettings.centerY = true;
acqSettings.xOffset = int64(0); % initial xy offsets are overwritten on startup
acqSettings.yOffset = int64(0);
acqSettings.xSize = int64(520); % Actual size of acquired images, x direction should be multiples of 10 for 10-tap CL transfer
acqSettings.ySize = int64(520);
acqSettings.xDisplaySize = int64(512); % Cropped version (to avoid bad lines, make a power to 2, etc)
acqSettings.yDisplaySize = int64(512);
acqSettings.xDisplayActualSize = 512; % If resizing is used
acqSettings.yDisplayActualSize = 512;

% Consecutive frames to average for real-time display
acqSettings.displayFrameAverage = 16;

% Bit depth 
acqSettings.bitDepth = 8;
acqSettings.pixelFormat = 'Mono8';

% Gain
acqSettings.gain = 33; % 33 in min, then gain is 33/32; see documentation

% Number of frames to average for each calibration step
acqSettings.numCalibrationFrames = 256;

% Display filter sigma (in pixels)
acqSettings.filterSigma = 24;

% Number of frames to capture
acqSettings.numCaptureFrames = 320; % needs to be >= number of averaged calibration frames

% Max memory to allocate in MB
acqSettings.maxMemMB = 8*1024; % 8 GB

% Exposure time (in microseconds)
acqSettings.exposureTime = 2200;

% Mirror flip time (measured 150 ms, but round up to be safe)
acqSettings.mirrorFlipTime = 0.2; % sec

% Note whether a calibration has been acquired (not yet)
acqSettings.calibrationAcquired = false;

% Number of refreshes to use in calculating the average refresh rate
acqSettings.refreshRateFrames = 8;

% Number of frames in each axial stack (i.e. volume) & frame index to
% display during each preview frame refresh
acqSettings.numFramesPerVolume = 16; 
acqSettings.displayFrame = 5;

% Function generator parameters
acqSettings.fgComPort = 'COM5';
acqSettings.fgBaudRate = 115200;
acqSettings.fgAmp = 10;  % technically Vpp, so half this for real amplitude



