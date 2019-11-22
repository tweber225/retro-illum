% Default settings and notes on usage

% Save data directory
acqSettings.dataPath = 'T:\retro-illum';

% Note session start time
acqSettings.sessionStartTime = datestr(datetime);
acqSettings.captureStartTime = 'none';

% Image Acquisition Toolbox Adapter name
acqSettings.adapterName = 'gentl';

% Image size / ROI
acqSettings.centerX = 'True';
acqSettings.centerY = 'True';
acqSettings.xOffset = 0;
acqSettings.yOffset = 0;
acqSettings.xSize = 1536;
acqSettings.ySize = 1088;
acqSettings.xDisplaySize = 1024;
acqSettings.yDisplaySize = 1024;
acqSettings.xDisplayActualSize = 768;
acqSettings.yDisplayActualSize = 768;

% Consecutive frames to average for real-time display
acqSettings.displayFrameAverage = 9;

% Bit depth 
acqSettings.bitDepth = 8;
acqSettings.pixelFormat = 'Mono8';

% Gain
acqSettings.gain = 0;

% Number of frames to average for background
acqSettings.numBackgroundFrames = 256;

% Display filter sigma (in pixels
acqSettings.filterSigma = 24;

% Number of frames to capture
acqSettings.numCaptureFrames = 1024;

% Max memory to allocate in MB
acqSettings.maxMemMB = 8*1024; % 8 GB

% Exposure time (in microseconds)
acqSettings.exposureTime = 5845;

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
acqSettings.thumbOptsScaleDownFactor = 0.75;
acqSettings.thumbOptsXCropWidth = 1024;
acqSettings.thumbOptsYCropWidth = 1024;
acqSettings.thumbOptsMaxGPUVarSize = 2^30; % 1 GB

