function handles = update_displays(handles)


% Update frame period and frequency
str = ['Frame Period: ' num2str(round(100000/handles.acqSettings.resultingFrameRate)/100) ' ms' newline 'Frame Rate: ' num2str(handles.acqSettings.resultingFrameRate) ' fps'];
set(handles.textDisplayFrameTime,'String',str)


% Memory/Capture stuff
frameMB = double(handles.acqSettings.xSize)*double(handles.acqSettings.ySize)/2^20;
stackMB = num2str(round(handles.acqSettings.numCaptureFrames*frameMB));
stackTime = num2str(.1*round(10*handles.acqSettings.numCaptureFrames*(handles.acqSettings.resultingFrameRate^(-1))));

str = ['Capture Time: ' stackTime ' s' newline 'Allocation: ' stackMB ' MB'];
set(handles.textDisplayCaptureMemoryTime,'String',str)

