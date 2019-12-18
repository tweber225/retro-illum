function scaledImg8b = scale_single_to_uint8(singleImg)

scaledImg8b = uint8(128 + 127.*singleImg);