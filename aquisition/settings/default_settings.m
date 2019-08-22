% Default settings and notes on usage
% All of this is for PCO Pixelfly USB with 

% Note session start time
acqSettings.sessionStartTime = datestr(datetime);
acqSettings.captureStartTime = 'none';

% Sensor format: 0 for standard (1392x1040), 1 for "extended" (800x600)
acqSettings.sensorFormat = 1;

% Pixel Rate (clock): 1 for 12 MHz, 2 for 24 MHz
acqSettings.pixelRate = 2; 

% Conversion Factor (gain): this is 100X the INVERSE gain in photoelectrons
% (e-) per ADU count. So 100 means 1.00 e-/ADU, and 150 would be lower gain
acqSettings.conversionFactor = 100; 

% Double Image mode enable (for short interframe time)
acqSettings.doubleImageMode = 1;

% IR Sensitivity enable
acqSettings.IRSensitivity = 1;

% Trigger mode: 0 for auto (i.e. freerun/max framerate)
acqSettings.triggerMode = 0; 

% Hot Pixel Correction Mode enable
acqSettings.hotPixelCorrectionMode = 0;

% Time stamping mode: 0 is off, 1 is binary in first few pixels, 2 is
% binary and ASCII, 3 is ASCII only (doesn't work)
acqSettings.timestampMode = 0; 

% Number of frames to average for background
acqSettings.numBackgroundFrames = 32;

% Number of frames to capture
acqSettings.numCaptureFrames = 64;

% Max memory to allocate in MB
acqSettings.maxMemMB = 2000;

% Exposure time (see next setting for time base)
acqSettings.exposureTime = 5;

% Exposure time base: 2 for ms, 1 for us, 0 for ns
acqSettings.exposureTimeBase = 2;

% Number of SDK buffers to use
acqSettings.numBuffers = 4;

% Note the whether a background has been acquired (not yet)
acqSettings.backgroundAcquired = 0;

% Displays time waited for buffer (for debugging)
acqSettings.dispBufferWaitTime = 1;

% Bandpass filter settings -- set to 0 to disable
acqSettings.BPLow = .02;
acqSettings.BPHigh = .0;

