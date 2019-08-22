function handles = save_settings(handles)
% Function to automatically save all the settings in settings structure.
% Prints the field name, the intended type of data, and the value converted
% into string characters, one line per field, in a text file.

fieldNamesArray = fieldnames(handles.acqSettings);
settingValuesArray = struct2cell(handles.acqSettings);

settingsFilename = 'settings.txt';

fileID = fopen([handles.acqSettings.captureDirectory filesep settingsFilename],'a');

for settingIdx = 1:numel(fieldNamesArray)
    switch class(settingValuesArray{settingIdx})
        case 'char'
            fprintf(fileID,'%s char %s\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
        case 'int32'
            fprintf(fileID,'%s int32 %d\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
        case 'uint32'
            fprintf(fileID,'%s uint32 %d\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
        case 'uint16'
            fprintf(fileID,'%s uint16 %d\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
        case 'double'
            % Couple special cases need to be handled differently
            if numel(settingValuesArray{settingIdx}) > 1 
                % if the setting is an array, convert whole array to string
                fprintf(fileID,'%s doubleArray %s\r\n',fieldNamesArray{settingIdx},mat2str(settingValuesArray{settingIdx}));
            elseif settingValuesArray{settingIdx} == round(settingValuesArray{settingIdx})
                 % if it's an integer but double type, skip the sci notation for readability
                fprintf(fileID,'%s double %d\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
            else
                fprintf(fileID,'%s double %.10e\r\n',fieldNamesArray{settingIdx},settingValuesArray{settingIdx});
            end
    end
end

fclose(fileID);
