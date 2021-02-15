function out = OTFa(sfCutoff,sfCutoffi,k,zPosIdx,sfIdx)

% Compute a few factors
H_det = H(sfIdx,sfCutoff);
H_illum = abs(H(-sfIdx,sfCutoffi)).^2;
G1 = G(sfIdx,k,-zPosIdx);
D1 = D(sfIdx,k,zPosIdx);

% Convolve effective partially coherent transmission CSFs in the frequency domain
p1 = H_det.*G1.*H_illum;
p2 = conj(H_det).*D1;
o1 = ifft2(fft2(p1).*fft2(p2));

p1 = H_det.*conj(D1);
p2 = conj(H_det).*conj(G1).*circshift(rot90(H_illum,2),[1 1]);
o2 = ifft2(fft2(p1).*fft2(p2));

out = o1 - o2; % add for phase OTF