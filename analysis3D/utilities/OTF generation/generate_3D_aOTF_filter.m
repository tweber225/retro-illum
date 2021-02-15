function OTF3DFilter = generate_3D_aOTF_filter(sfCutoff,sfCutoffi,k,focalPlanes,sfIdx,filterThreshold)

% Shift the focal planes so they are in FFT-style ordering (DC in vector
% position #1)
shiftedFocalPlanes = ifftshift(focalPlanes);

% Extend the range of the spatial frequency index (sfIdx) to avoid issues
% with circular convolution performed in frequency domain
dSf = mean(diff(sfIdx));
sfIdxNew = 2*min(sfIdx):dSf:(-2*min(sfIdx));

% Compute the (2D) absorption OTF as basis
OTFFocalPlanes = OTFa(sfCutoff,sfCutoffi,k,shiftedFocalPlanes,sfIdxNew);

% FT in 3rd dimension to make this a full 3D OTF
OTF3D = fft(OTFFocalPlanes,[],3);

% Crop back to desired size
OTF3D = fftshift3(OTF3D);
OTF3D = ifftshift3(OTF3D((end/4+1):(3*end/4),(end/4+1):(3*end/4),:));


% Threshold the magnitude to generate binary 3D filter
OTF3DFilter = abs(OTF3D) > filterThreshold;


