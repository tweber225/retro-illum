function fgHandle = set_up_function_generator(fgCommPort,fgBaudRate)
serialPauseTime = .005;

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

% Make positive-only ramp function and set as arbitrary wave #1
waveformLength = 2048;
arbWave = 1023*linspace(0,2,waveformLength)' + 2048;
arbWaveStr = sprintf('%.0f,',arbWave);
writeline(fgHandle,[':a01=' arbWaveStr]);pause(2);

% Switch to arbitrary wave 1
writeline(fgHandle,':w21=101.');pause(serialPauseTime);

% Set frequency
f = 2*51.6476;
fStr = num2str(round(f*100));
writeline(fgHandle,[':w23=' fStr ',0.']);pause(serialPauseTime);

% Set amplitude ([sic], acutally this is Vpp = 2*amplitude)
a = 5;
aStr = num2str(round(a*1000));
writeline(fgHandle,[':w25=' aStr '.']);pause(serialPauseTime);

% Set up triggering
% Switch to Modulation Mode panel -> Function:BST (burst) CH1
writeline(fgHandle,':w33=9.');pause(serialPauseTime);

% Set Mode (trigger source) to External DC
writeline(fgHandle,':w50=3.');pause(serialPauseTime);

% Set # (cycles) to 1 (per trigger), automatically turns ON
writeline(fgHandle,':w49=1.');pause(serialPauseTime);

