function save_captured_image_stack(captureStack,backgroundImg,saveDirectory)

% Save the raw stack as 8-bit tiff stack
capturePath = [saveDirectory filesep 'raw.tif'];
saveastiff(captureStack,capturePath);

% If background is not all 0's, save background file
if sum(backgroundImg(:).^2) ~= 0
    backgroundPath = [saveDirectory filesep 'background.tif'];
    saveastiff(backgroundImg,backgroundPath);
end

