function stack = make_hyperstack(stack,numZPlanes)

sizeArray = [size(stack,1),size(stack,2),numZPlanes,size(stack,3)/numZPlanes];

stack = reshape(stack,sizeArray);