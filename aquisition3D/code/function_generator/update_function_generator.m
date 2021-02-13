function update_function_generator(fgHandle,newFreq,newAmp)
serialPauseTime = .05;

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
fStr = num2str(round(newFreq*100));
writeline(fgHandle,[':w23=' fStr ',0.']);pause(serialPauseTime);

% Set amplitude
aStr = num2str(round(newAmp*1000));
writeline(fgHandle,[':w25=' aStr '.']);pause(serialPauseTime);

% Set up triggering
% Switch to Modulation Mode panel -> Function:BST (burst) CH1
writeline(fgHandle,':w33=9.');pause(serialPauseTime);

% Set Mode (trigger source) to External DC
writeline(fgHandle,':w50=3.');pause(serialPauseTime);

% Set # (cycles) to 1 (per trigger), automatically turns ON
writeline(fgHandle,':w49=1.');pause(serialPauseTime);

disp('Updated function generator')