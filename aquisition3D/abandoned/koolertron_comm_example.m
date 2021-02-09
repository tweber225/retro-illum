% This example demonstrates several ways to communicate with the Function Generator
% Make sure you have installed the CH340 driver (check lab U drive \software)
% With driver installed, the func gen will appear in Device Manager under "Ports"
% Make sure your MATLAB version is 2019b or later (for "serialport" command)
%% Parameters
serialPauseTime = 0.01;
fgCommPort = 'COM5';
defaultBaudRate = 115200;


%% Open connection to Function Generator
disp('Opening connection with Koolertron function generator')

% Make serial port object & connect
fg = serialport(fgCommPort,defaultBaudRate);pause(serialPauseTime);
configureTerminator(fg,'CR/LF');pause(serialPauseTime);

% Just in case: turn off both channels
writeline(fg,':w20=0,0.');pause(serialPauseTime);



%% Set up triggering
% Switch to Modulation Mode panel -> Function:BST (burst) CH1
writeline(fg,':w33=9.');pause(serialPauseTime);

% Set Mode (trigger source) to External DC
writeline(fg,':w50=3.');pause(serialPauseTime);

% Set # (cycles) to 1 (per trigger), automatically turns ON
writeline(fg,':w49=1.');pause(serialPauseTime);


%% Set up initial wave

% Set to triangle wave
writeline(fg,':w21=3.');pause(serialPauseTime);

% Set frequency
f = 475.5;
fStr = num2str(round(f*100));
writeline(fg,[':w23=' fStr ',0.']);pause(serialPauseTime);

% Set offset
writeline(fg,[':w27=1000.']);pause(serialPauseTime);

% Set amplitude ([sic], acutally this is Vpp = 2*amplitude)
a = 2.135;
aStr = num2str(round(a*1000));
writeline(fg,[':w25=' aStr '.']);pause(serialPauseTime);


%% Make triangle wave, send as arbitrary wave
waveformLength = 2048;
t = linspace(0,2*pi,waveformLength+1);
t = t(1:(end-1));
arbWave = sawtooth(t,0.5)*1024 + 2048+1023;
arbWaveStr = sprintf('%.0f,',arbWave);

writeline(fg,[':a01=' arbWaveStr])


%% Close out
delete(fg)


