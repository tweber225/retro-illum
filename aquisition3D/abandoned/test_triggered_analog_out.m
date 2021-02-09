% Quick test to see whether triggering analog output works

% Create session
s = daq.createSession('ni');

% Add analog output
s.addAnalogOutputChannel('Dev2', 0, 'Voltage');

% Set scan rate ...
s.Rate = 5000;

% Add an external start trigger  
s.addTriggerConnection('external','Dev2/PFI1','StartTrigger');

% Queue the data you want to output
s.queueOutputData(linspace(0,4,10)');

% Set Triggers per run to be how many times you want the channel   
% to run.
s.TriggersPerRun = Inf;
% can it be Inf?

%s.startForeground;
s.startBackground;

% or can it be background?
snapnow;