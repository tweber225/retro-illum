function daqHandle = initialize_DAQ(numPins)

% Make the DAQ session
daqHandle = daq.createSession('ni');

% Add port/line combination as channel
portLineString = ['Port0/Line0:' num2str(numPins-1)];
addDigitalChannel(daqHandle,'Dev1',portLineString,'OutputOnly');

% Output initial signals [false true] first sent to flip mirror and
% microscopy LED and secound is sent to pupil cam LED
digitalOutputScan = zeros([1 numPins],'logical');
digitalOutputScan(2) = true;
outputSingleScan(daqHandle,digitalOutputScan);

% Get name of device
devices = daq.getDevices;

% Display DAQ Initialized
disp(['DAQ initialized (' devices(1).Description ')'])