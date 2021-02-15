% Add subfolders to path
analysisPath = strsplit(mfilename('fullpath'),filesep); % Get full path
analysisPath = strjoin(analysisPath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(analysisPath)); % add subfolders

% Input file names
dataFileName = 'test_stack.tif';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\XY jog\181527358';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\XY jog\181539438';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Y jog\174156342';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Y jog\174203906';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Z jog\183358033';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Z jog\183415206';
%dataDir1 = 'C:\Users\MertzLabAdmin\data\20210213\Z 20 um X 10 um\183917537';
%dataDir2 = 'C:\Users\MertzLabAdmin\data\20210213\Z 20 um X 10 um\184001178';
dataDir1 = 'C:\Users\MertzLabAdmin\data\20210214\211512917';

% Load datasets
acqSettings = load_settings(dataDir1); % both stacks should have pretty much the same settings
hStack1 = make_hyperstack(load_tiff_stack([dataDir1 filesep dataFileName]),acqSettings.numFramesPerVolume/2);
%hStack2 = make_hyperstack(load_tiff_stack([dataDir2 filesep dataFileName]),acqSettings.numFramesPerVolume/2);
calib = load_tiff_stack([dataDir1 filesep 'calibration.tif']);

% Concatenate hyperstacks and correct with calibration
%hStackCorr = single(cat(4,hStack1,hStack2))./calib;
hStackCorr = single(hStack1)./calib;


% Crop corrected hyperstacks
hStackCorr = hStackCorr(9:520,5:516,2:7,:);

% Subtract off mean value
hStackCorr = hStackCorr - imgaussfilt(hStackCorr,100);

% Allocate space for a volume coverage map (to track volume registered to
% specific place)
coverageVol = ones(size(hStackCorr(:,:,:,1)),'single');

% Fix tunable lens-dependent magnification
magCorrectFactor = -.009;
hStackCorr = magnify_about_point(hStackCorr,1+linspace(-1,1,size(hStackCorr,3))*magCorrectFactor);
coverageVol = magnify_about_point(coverageVol,1+linspace(-1,1,size(hStackCorr,3))*magCorrectFactor);

% Zero pad in XYZ to allow for space in mosaicing
originalHStackSize = size(hStackCorr(:,:,:,1));
hStackCorr = padarray(hStackCorr,originalHStackSize/2,0,'both');
coverageVol = padarray(coverageVol,originalHStackSize/2,0,'both');
singleVolCoverage = coverageVol;

% Compute 3D Fourier Transform of each image stack
spectra = fft3(hStackCorr);

%% Compute 3D OTF filter (this doesn't need to be perfect)
% Settings
wl = .850;
NA = .4;
filterThreshold = 10000;
dz = 6;
pixSize = 5.5/8.8;

% Argument computations
k = 1/wl;
sfCutoff = NA*k;
sfCutoffi = sfCutoff;
maxSf = single(1/(2*pixSize));
dSf = 2*maxSf/size(hStackCorr,1);
cropSfIdx =  -maxSf:dSf:(maxSf-dSf);
mosaicFocalPlanes = -(size(hStackCorr,3)/2-1/2)*dz:dz:(size(hStackCorr,3)/2-1/2)*dz;

OTF3DFilter = generate_3D_aOTF_filter(sfCutoff,sfCutoffi,k,mosaicFocalPlanes,cropSfIdx,filterThreshold);


%% Begin 3D mosaicing
% Initialize the summing volume with the first frame
sumStack = hStackCorr(:,:,:,1);

% Track shifts, and XC peaks
shiftAmounts = zeros(size(hStackCorr,4),3);
XCPeakVals = zeros(size(hStackCorr,4),1);

% Cross correlate to growing mosaic with each subsequent volume
for tIdx = 2:size(hStackCorr,4)
    % Calculate the new "average" stack
    avgStack = sumStack./(coverageVol+eps);
    
    % Perform frequency-domain cross correlation and upsample 
    XPowSpec = fft3(avgStack).*conj(spectra(:,:,:,tIdx));
    XPowSpecNorm = XPowSpec./(abs(XPowSpec) + eps('single'));
    xPowSpecFiltered = XPowSpecNorm.*OTF3DFilter;
    XC = abs(fftshift3(abs(ifft3(xPowSpecFiltered))));
    
    % Collect maximum subscripts in xCorr
    [maxVal,maxIdx] = max(XC(:));
    XCPeakVals(tIdx) = maxVal;
    [yPk,xPk,zPk] = ind2sub(size(XC),maxIdx);
    
    % Shift the stack and sum into sumStack
    shiftAmounts(tIdx,:) = [yPk,xPk,zPk] - [size(sumStack,1)/2+1,size(sumStack,2)/2+1,size(sumStack,3)/2+1];
    sumStack = sumStack + circshift(hStackCorr(:,:,:,tIdx),-shiftAmounts(tIdx,:));
    
    % Shift the onesStack and add to numAveragedStack
    coverageVol = coverageVol + circshift(singleVolCoverage,-shiftAmounts(tIdx,:));
    
    % Display mosaic in process
    imagesc(avgStack(:,:,8));axis equal;colormap gray; title(num2str(tIdx))
    drawnow
    
    % Show cross-correlation
%     if tIdx == 32
%         imagesc(XC(yPk-15:yPk+15,xPk-15:xPk+15,zPk));axis equal
%         drawnow
%     end

    
end

% Calculate one last average stack
avgStack = sumStack./(coverageVol+eps);