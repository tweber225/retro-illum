function fgHandle = set_up_function_generator(fgCommPort,fgBaudRate,freq,amp)
serialPauseTime = .05;

% Check inputs
if ~strcmp(class(fgCommPort),'char')
    error('Check format of fgCommPort (arg #1), should be a character string');
end

fgBaudRate = round(fgBaudRate);
if fgBaudRate > 2e5
    fgBaudRate = 2e5;
elseif fgBaudRate < 1000
    fgBaudRate = 1000;
end

% Open the connection
fgHandle = serialport(fgCommPort,fgBaudRate);pause(serialPauseTime);
configureTerminator(fgHandle,'CR/LF');pause(serialPauseTime);

% Just in case: turn off both channels
writeline(fgHandle,':w20=0,0.');pause(serialPauseTime);

% Make positive-only sinusoid
waveformLength = 2048;
phaseShift = -80;
arbWave = 1023*sin(2*pi*(1:waveformLength)'/waveformLength);

% Shift minimum point to first index point & raise waveform to be >= 0
[minVal,minIdx] = min(arbWave);
shiftedWave = circshift(arbWave,-minIdx-phaseShift) - minVal + 2048;

% Set as arbitrary wave #1
arbWaveStr = sprintf('%.0f,',shiftedWave);
writeline(fgHandle,[':a01=' arbWaveStr]);pause(.5);

% Switch to arbitrary wave 1
writeline(fgHandle,':w21=101.');pause(serialPauseTime);

% Set frequency
fStr = num2str(round(freq*100));
writeline(fgHandle,[':w23=' fStr ',0.']);pause(serialPauseTime);

% Set amplitude
aStr = num2str(round(amp*1000));
writeline(fgHandle,[':w25=' aStr '.']);pause(serialPauseTime);

% Set offset (0V = 1000)
writeline(fgHandle,':w27=1000.');pause(serialPauseTime);

% Set up triggering
% Switch to Modulation Mode panel -> Function:BST (burst) CH1
writeline(fgHandle,':w33=9.');pause(serialPauseTime);

% Set Mode (trigger source) to External DC
writeline(fgHandle,':w50=3.');pause(serialPauseTime);

% Set # (cycles) to 1 (per trigger), automatically turns ON
writeline(fgHandle,':w49=1.');pause(serialPauseTime);

disp('Function generator opened')
