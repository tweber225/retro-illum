function save_captured_double_image_stacks(captureStack,backgroundImg,saveDirectory)

% Save the raw stack as 16-bit tiff
capturePath = [saveDirectory filesep 'raw.tif'];
saveastiff(captureStack,capturePath);

% If background is not all 0's, save background file
if sum(backgroundImg(:).^2) ~= 0
    backgroundPath = [saveDirectory filesep 'background.tif'];
    saveastiff(backgroundImg,backgroundPath);
    
    % Correct stack
    captureStack = single(captureStack)-single(backgroundImg(:,:,ones(1,size(captureStack,3))));
    
end

% If in double-image mode (when there are more rows than columns), do norm
% difference processing
if size(captureStack,1) > size(captureStack,2)
    normDiffPath = [saveDirectory filesep 'norm_diff.tif'];
    
    diffImg = single(captureStack(1:end/2,:,:)) - single(captureStack((end/2+1):end,:,:)); 
    sumImg = single(captureStack(1:end/2,:,:)) + single(captureStack((end/2+1):end,:,:));
    clear captureStack
    sumImg(sumImg == 0) = eps('single'); % prevent any infinities
    
    normDiff = diffImg./(sumImg);
    clear diffImg
    clear sumImg
    
    saveastiff(normDiff,normDiffPath);
    
end