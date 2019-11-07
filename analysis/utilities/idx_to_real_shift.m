function shift = idx_to_real_shift(idx,sz)

shift = single(idx)-1;

shift = shift - sz/2;

shift = mod(shift,sz);

shift = shift - sz/2;
