function thumbOpts = make_thumb_opts_struct(acqSettings)


thumbOpts.filterSigma = acqSettings.thumbOptsFilterSigma;
thumbOpts.scaleDownFactor = acqSettings.thumbOptsScaleDownFactor;
thumbOpts.xCropWidth = acqSettings.thumbOptsXCropWidth;
thumbOpts.yCropWidth = acqSettings.thumbOptsYCropWidth;
thumbOpts.maxGPUVarSize = acqSettings.thumbOptsMaxGPUVarSize;