%clc
clear all
yDim = 1024;
xDim = 1024;
zDim = 4;

imgStack = uint8(255*rand(yDim,xDim,zDim));
calibFrame = single(rand(yDim,xDim));


% Time to send to GPU
toGPU1 = gputimeit(@()gpuArray(imgStack),1);
toGPU2 = gputimeit(@()gpuArray(calibFrame),1);

% Send to GPU
imgStackGPU = gpuArray(imgStack);
calibFrameGPU = gpuArray(calibFrame);

% Summing timing on GPU
sum3d = @(iStk) (sum(single(iStk),3,'native'));
GPUTime = gputimeit(@() sum3d(imgStackGPU));
disp(GPUTime)

sumResultGPU = sum3d(imgStackGPU);

% Summing timing on CPU
CPUTime = timeit(@() sum3d(imgStack));
disp(CPUTime)
