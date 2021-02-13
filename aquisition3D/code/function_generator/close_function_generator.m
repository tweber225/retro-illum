function close_function_generator(fgHandle)
serialPauseTime = .05;

% Turn off the output channels
writeline(fgHandle,':w20=0,0.');pause(serialPauseTime);

% Delete the handle to close the connection
delete(fgHandle)

disp('Function generator closed')




