% Add subfolders to path
analysisPath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisPath = strjoin(analysisPath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisPath)); % add subfolders

% Input file names
dataDir = 'C:\Users\MertzLabAdmin\data\20210212\191137123';
dataFileName = 'test_stack.tif';

% Load data
acqSettings = load_settings(dataDir);
hStack = make_hyperstack(load_tiff_stack([dataDir filesep dataFileName]),acqSettings.numFramesPerVolume/2);
calib = load_tiff_stack([dataDir filesep 'calibration.tif']);
hStackCorr = single(hStack)./calib;




