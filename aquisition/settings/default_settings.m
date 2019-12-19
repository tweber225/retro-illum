% Default settings and notes on usage

% Camera SN
acqSettings.cameraSerialNumber = '23187241';

% Save data directory
acqSettings.dataPath = 'C:\Users\MertzLabAdmin\retro-illum\data';

% Camera configuration directory
acqSettings.saperaConfigFilePath = 'C:\Users\MertzLabAdmin\retro-illum\cam configs\B_acA2040-180kmNIR_10tap8bit_fullarea.cca';

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
acqSettings.xSize = int64(1540);
acqSettings.ySize = int64(1088);
acqSettings.xDisplaySize = int64(1024);
acqSettings.yDisplaySize = int64(1024);
acqSettings.xDisplayActualSize = 768;
acqSettings.yDisplayActualSize = 768;

% Consecutive frames to average for real-time display
acqSettings.displayFrameAverage = 9;

% Bit depth 
acqSettings.bitDepth = 8;
acqSettings.pixelFormat = 'Mono8';

% Gain
acqSettings.gain = 33; % 33 in min, then gain is 33/32; see documentation

% Number of frames to average for background
acqSettings.numBackgroundFrames = 256;

% Display filter sigma (in pixels
acqSettings.filterSigma = 24;

% Number of frames to capture
acqSettings.numCaptureFrames = 1024;

% Max memory to allocate in MB
acqSettings.maxMemMB = 8*1024; % 8 GB

% Exposure time (in microseconds)
acqSettings.exposureTime = 3200;

% Note whether a calibration has been acquired (not yet)
acqSettings.calibrationAcquired = false;

% GPIO settings
acqSettings.GPIO1Name = 'Line3';
acqSettings.GPIO1LineMode = 'Output';
acqSettings.GPIO1LineSource = 'ExposureActive';
acqSettings.GPIO1LineInverter = 'True';
acqSettings.GPIO2Name = 'Line4';
acqSettings.GPIO2LineMode = 'Output';
acqSettings.GPIO2LineSource = 'ExposureActive';
acqSettings.GPIO2LineInverter = 'False';

% Number of refreshes to use in calculating the average refresh rate
acqSettings.refreshRateFrames = 16;

% Thumbnail image processing parameters
acqSettings.thumbOptsFilterSigma = 25;
acqSettings.thumbOptsScaleDownFactor = 0.5;
acqSettings.thumbOptsXCropWidth = 1024;
acqSettings.thumbOptsYCropWidth = 1024;
acqSettings.thumbOptsMaxGPUVarSize = 2^30; % 1 GB

