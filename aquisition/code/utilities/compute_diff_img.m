function [chan1,chan2,diffImg] = compute_diff_img(corrDoubleImg)

dImgSize = size(corrDoubleImg);
chan1YStart = 1;
chan1YEnd = dImgSize(1)/2;
chan2YStart = dImgSize(1)/2 + 1;
chan2YEnd = dImgSize(1);

% Separate the two channels 
chan1 = corrDoubleImg(chan1YStart:chan1YEnd,:);
chan2 = corrDoubleImg(chan2YStart:chan2YEnd,:);

diffImg = filteredImg1-filteredImg2;
chan1 = uint16(chan1);
chan2 = uint16(chan2);


