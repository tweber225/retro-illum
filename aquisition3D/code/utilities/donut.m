function result = donut(x,y,rLow,rHigh)

rSqr = x.^2 + y.^2;
result = rSqr < (rHigh^2) && rSqr > (rLow^2);