function imageOut = magnify_about_point(imageIn,scales)

if size(imageIn,3) ~= numel(scales)
    error('number of image slices and scales vector need to be same')
end


% Define original coordinate
centerPoint = size(imageIn)/2 + 1/2;
originalGridY = (1:size(imageIn,1))'-centerPoint(1);
originalGridX = (1:size(imageIn,2))-centerPoint(2);

imageOut = zeros(size(imageIn),'single');
for sliceIdx = 1:size(imageIn,3)

    % Define new coordinate to interpolate
    newGridY = originalGridY*scales(sliceIdx);
    newGridX = originalGridX*scales(sliceIdx);

    % Process interpolation
    imageOut(:,:,sliceIdx) = interp2(originalGridX,originalGridY,single(imageIn(:,:,sliceIdx)),newGridX,newGridY,'linear',0);
    
end