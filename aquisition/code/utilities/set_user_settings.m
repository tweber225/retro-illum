function handles = set_user_settings(handles)

% Set parameters, use PCO's subfunctions when possible
errorCode = calllib('PCO_CAM_SDK','PCO_SetSensorFormat',handles.out_ptr,handles.acqSettings.sensorFormat);
pco_errdisp('PCO_SetSensorFormat',errorCode);

handles.subfunc.fh_set_pixelrate(handles.out_ptr,handles.acqSettings.pixelRate);

errorCode = calllib('PCO_CAM_SDK','PCO_SetConversionFactor',handles.out_ptr,handles.acqSettings.conversionFactor);
pco_errdisp('PCO_SetConversionFactor',errorCode);

errorCode = calllib('PCO_CAM_SDK','PCO_SetDoubleImageMode',handles.out_ptr,handles.acqSettings.doubleImageMode);
pco_errdisp('PCO_SetDoubleImageMode',errorCode);

errorCode = calllib('PCO_CAM_SDK','PCO_SetIRSensitivity',handles.out_ptr,handles.acqSettings.IRSensitivity);
pco_errdisp('PCO_SetIRSensitivity',errorCode);

handles.subfunc.fh_set_triggermode(handles.out_ptr,handles.acqSettings.triggerMode);

errorCode = calllib('PCO_CAM_SDK','PCO_SetHotPixelCorrectionMode',handles.out_ptr,handles.acqSettings.hotPixelCorrectionMode);
pco_errdisp('PCO_SetHotPixelCorrectionMode',errorCode);

errorCode = calllib('PCO_CAM_SDK', 'PCO_SetTimestampMode',handles.out_ptr,handles.acqSettings.timestampMode);
pco_errdisp('PCO_SetTimestampMode',errorCode);  

handles.subfunc.fh_set_exposure_times(handles.out_ptr,handles.acqSettings.exposureTime,handles.acqSettings.exposureTimeBase,0,2) % 2's indicate ms timebase

