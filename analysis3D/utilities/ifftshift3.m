function out = ifftshift3(f)

out = ifftshift(ifftshift(ifftshift(f,1),2),3);