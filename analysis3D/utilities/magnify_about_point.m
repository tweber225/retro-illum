function imagesOut = magnify_about_point(imagesIn,scales)
% Works with 4D stacks, magnification factors applied to each slice (dim3)


if size(imagesIn,3) ~= numel(scales)
    error('number of image slices and scales vector need to be same')
end


% Define original coordinate
centerPoint = size(imagesIn)/2 + 1/2;
originalGridY = (1:size(imagesIn,1))'-centerPoint(1);
originalGridX = (1:size(imagesIn,2))-centerPoint(2);

imagesOut = zeros(size(imagesIn),'single');
for sliceIdx = 1:size(imagesIn,3)

    % Define new coordinate to interpolate
    newGridY = originalGridY*scales(sliceIdx);
    newGridX = originalGridX*scales(sliceIdx);

    % Process interpolation for each time point
    for tIdx = 1:size(imagesIn,4)
        imagesOut(:,:,sliceIdx,tIdx) = interp2(originalGridX,originalGridY,single(imagesIn(:,:,sliceIdx,tIdx)),newGridX,newGridY,'linear',0);
    end
end