% Default settings and notes on usage
% All of this is for PCO Pixelfly USB with 

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
acqSettings.xDisplaySize = 768;
acqSettings.yDisplaySize = 768;

% Consecutive frames to average for real-time display
acqSettings.displayFrameAverage = 4;

% Bit depth (for this application always 8-bit)
acqSettings.bitDepth = 8;
acqSettings.pixelFormat = 'Mono8';

% Gain
acqSettings.gain = 0;

% Number of frames to average for background
acqSettings.numBackgroundFrames = 256;

% Display filter sigma (in pixels
acqSettings.filterSigma = 25;

% Number of frames to capture
acqSettings.numCaptureFrames = 256;

% Max memory to allocate in MB
acqSettings.maxMemMB = 8000;

% Exposure time (in microseconds)
acqSettings.exposureTime = 5845;

% Note whether a background has been acquired (not yet)
acqSettings.backgroundAcquired = 0;

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
acqSettings.refreshRateFrames = 10;

