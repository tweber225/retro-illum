function handles = set_user_settings(handles)

% Set and then Get various parameters

% Set (centered) sensor size on Basler Pylon SDK
handles.baslerCam.Parameters.Item('CenterX').SetValue(handles.acqSettings.centerX);
handles.baslerCam.Parameters.Item('CenterY').SetValue(handles.acqSettings.centerY);
handles.baslerCam.Parameters.Item('Width').SetValue(handles.acqSettings.xSize);
handles.baslerCam.Parameters.Item('Height').SetValue(handles.acqSettings.ySize);

% Get updated sensor size
handles.acqSettings.centerX = handles.baslerCam.Parameters.Item('CenterX').GetValue;
handles.acqSettings.centerY = handles.baslerCam.Parameters.Item('CenterY').GetValue;
handles.acqSettings.xOffset = handles.baslerCam.Parameters.Item('OffsetX').GetValue;
handles.acqSettings.yOffset = handles.baslerCam.Parameters.Item('OffsetY').GetValue;
handles.acqSettings.xSize = handles.baslerCam.Parameters.Item('Width').GetValue;
handles.acqSettings.ySize = handles.baslerCam.Parameters.Item('Height').GetValue;

% Update ROI on frame grabber SDK
handles.vid.ROIPosition = double([handles.acqSettings.xOffset handles.acqSettings.yOffset handles.acqSettings.xSize handles.acqSettings.ySize]);

% Set gain
handles.baslerCam.Parameters.Item('GainRaw').SetValue(handles.acqSettings.gain);
handles.acqSettings.gain = handles.baslerCam.Parameters.Item('GainRaw').GetValue;

% Set exposure
handles.baslerCam.Parameters.Item('ExposureTimeAbs').SetValue(handles.acqSettings.exposureTime);
handles.acqSettings.exposureTime = handles.baslerCam.Parameters.Item('ExposureTimeAbs').GetValue;

