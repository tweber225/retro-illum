function stackOut = load_binary_stack(stackPath,dims,bitDepth)
tic

% Make precision string 8 or 16 bit pixels
bytesPerPixel = ceil(bitDepth/8);
dataPrecision = ['*uint' num2str(8*bytesPerPixel)];

% Check that file size and dimensions agree
fileStruct = dir(stackPath);
totalElements = prod(dims);
if fileStruct.bytes/totalElements ~= bytesPerPixel
    error('File size/dimensions mismatch');
end

% Read binary file
fileID = fopen(stackPath);
allData = fread(fileID,totalElements,dataPrecision);
fclose(fileID);

% Reshape the data into stack dimensions
stackOut = reshape(allData,dims);

% Confirm read
disp(['Read file: ' stackPath ' (' num2str(toc) ' sec)'])
