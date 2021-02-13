function resultGPU = make_donut_filt(ySize,xSize,minRho,maxRho)

xMin = -single(xSize)/2;
xMax = single(xSize)/2-1;
yMin = -single(ySize)/2;
yMax = single(ySize)/2-1;

smallerSize = single(min(xSize,ySize))/2;

xIdx = gpuArray.colon(xMin,xMax);
yIdx = gpuArray.colon(yMin,yMax);

[xGr,yGr] = meshgrid(xIdx,yIdx);

resultGPU = ifftshift(arrayfun(@donut,xGr,yGr,minRho*smallerSize,maxRho*smallerSize));