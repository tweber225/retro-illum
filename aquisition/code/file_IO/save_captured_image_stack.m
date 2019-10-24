function save_captured_image_stack(captureStack,calibFrame,saveDirectory,thumbOpts)


%% Save the raw stack as .dat file (binary)
% (raw data isn't really directly viewable anyway, so not saving in tiff is fine)
tic
capturePath = [saveDirectory filesep 'raw.dat'];
rawFileID = fopen(capturePath,'w');
fwrite(rawFileID,captureStack(:));
fclose(rawFileID);
disp(['Wrote file: ' capturePath ' in ' num2str(toc) ' seconds'])

%% If background is not all 1's, save calibration file in single precision
% (this might be useful to have in tiff format)
tic
if sum((calibFrame(:)-1).^2) ~= 0
    backgroundPath = [saveDirectory filesep 'calibration.tif'];
    saveastiff(single(calibFrame),backgroundPath);
end
disp(['Wrote file: ' backgroundPath ' in ' num2str(toc) ' seconds'])

%% Save "thumbnail" version of the stack (cropped, PRNU-corr'ed & flattened)
tic
% Run thumbnail image processing
stack8b = make_thumbnail_stack_GPU(captureStack,calibFrame,thumbOpts);
processToc = toc;
% Then save the flattened stack
saveFileName = [saveDirectory filesep 'thumbnail.tif'];
saveastiff(stack8b,saveFileName);
writeToc = toc;
disp(['Processed thumbnail in ' num2str(processToc) ' sec and wrote file: ' saveFileName ' in ' num2str(writeToc) ' seconds'])
