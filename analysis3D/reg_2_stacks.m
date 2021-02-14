% Add subfolders to path
analysisPath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisPath = strjoin(analysisPath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisPath)); % add subfolders

% Input file names
dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\XY jog\181527358';
dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\XY jog\181539438';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Y jog\174156342';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Y jog\174203906';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Z jog\183358033';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Z jog\183415206';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Z 20 um X 10 um\183917537';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Z 20 um X 10 um\184001178';
dataFileName = 'test_stack.tif';

% Load data, correct with calibration
acqSettings = load_settings(dataDir1); % both stacks should have pretty much the same settings
hStack1 = make_hyperstack(load_tiff_stack([dataDir1 filesep dataFileName]),acqSettings.numFramesPerVolume/2);
hStack2 = make_hyperstack(load_tiff_stack([dataDir2 filesep dataFileName]),acqSettings.numFramesPerVolume/2);
calib = load_tiff_stack([dataDir1 filesep 'calibration.tif']);
hStackCorr1 = single(hStack1)./calib;
hStackCorr2 = single(hStack2)./calib;

% Crop stacks
hStackCorr1 = hStackCorr1(9:520,5:516,2:7,:);
hStackCorr2 = hStackCorr2(9:520,5:516,2:7,:);

% Take average of all the time points
stack1 = mean(hStackCorr1,4);
stack2 = mean(hStackCorr2,4);

% Apply magnification correction
magCorrectFactor = -0.0025;
stack1 = magnify_about_point(stack1,1+[-2 -1 0 0 1 2]*magCorrectFactor);
stack2 = magnify_about_point(stack2,1+[-2 -1 0 0 1 2]*magCorrectFactor);



% 3D registration (normalized Cross-Correlation)
F1 = fftshift3(fft3(stack1));
F2 = fftshift3(fft3(stack2));
XPowSpec = F1.*conj(F2);
XC = ifft3(XPowSpec./(abs(XPowSpec + eps(single(0)))));
XCminusBackground = abs(XC)-median(abs(XC),3);
[~,vIdx] = max(fftshift3(XCminusBackground),[],'all','linear');
[yPk,xPk,zPk] = ind2sub(size(XC),vIdx);
shiftVector = [yPk-(size(XC,1)/2+1),xPk-(size(XC,2)/2+1),zPk-(size(XC,3)/2+1)];

%% Show correspondence
shiftStack2 = circshift(stack2,-shiftVector);

for sliceIdx = 1:size(XC,3)
    resizedImage1 = imresize(shiftStack2(:,:,sliceIdx),2);
    resizedImage2 = imresize(stack1(:,:,sliceIdx),2);
    imshowpair(resizedImage1,resizedImage2)
    drawnow
    pause(1)
end





