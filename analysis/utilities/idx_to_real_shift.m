function shift = idx_to_real_shift(idx,sz,subPixelFactor)

shift = (single(idx)-1)./subPixelFactor;

shift = shift - sz/2;

shift = mod(shift,sz);

shift = shift - sz/2;
