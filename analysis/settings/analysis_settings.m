% List of parameters used in analysis

% Flattening parameters
analysisSettings.useGPU = true;
analysisSettings.targetGPUMemSize = 256*2^20; % 256 MB
analysisSettings.flatSigma = 24;
analysisSettings.maxSmoothingSpan = 15;

% Registration parameters
analysisSettings.regXCrop = 1024;
analysisSettings.regYCrop = 1024;
analysisSettings.MAOrder = 4; % MA: moving average
analysisSettings.subPixelRegFactor = 1; % FIX CIRCSHIFTING CODE for this!! precision is reciprocal
analysisSettings.MARegFramesPerChunk = 64;
analysisSettings.maxRho = .95; % Normalized parameters for circularly-symmetric bandpass of cross power spectrum
analysisSettings.minRho = 0.025;