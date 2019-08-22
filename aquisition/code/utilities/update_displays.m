function handles = update_displays(handles)


% Update frame period and frequency
framePeriodms = num2str(1000*handles.acqSettings.framePeriod,4);
frameRate = num2str(1/handles.acqSettings.framePeriod,4);
str = ['Frame Period: ' framePeriodms ' ms' newline 'Frame Rate: ' frameRate ' Hz'];
set(handles.textDisplayFrameTime,'String',str)


% Memory/Capture stuff
frameMB = 2*double(handles.acqSettings.xSize)*double(handles.acqSettings.ySize)/2^20;
stackMB = num2str(round(handles.acqSettings.numCaptureFrames*frameMB));
stackTime = num2str(round(handles.acqSettings.numCaptureFrames*handles.acqSettings.framePeriod));

str = ['Capture Time: ' stackTime ' s' newline 'Allocation: ' stackMB ' MB'];
set(handles.textDisplayCaptureMemoryTime,'String',str)

