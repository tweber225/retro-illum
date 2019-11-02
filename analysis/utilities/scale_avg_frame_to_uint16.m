function result = scale_avg_frame_to_uint16(avgFrame,numFrames)

result = uint16(avgFrame.*((single(2)^15)./numFrames) + single(2)^15);