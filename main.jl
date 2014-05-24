using NIfTI
using ImageView, Images
using Gadfly

function midpoint(val)
    convert(Int, val/2 + 1)
end

function normalize_ni(ni_data)
    raw = ni_data.raw
    raw_norm = raw - minimum(raw)
    raw_norm /= maximum(raw_norm)
    raw_norm
end

function display_brain_centers(ni_data)
    ni_size = size(ni_data)
    center_slice_1 = squeeze(ni_data[midpoint(ni_size[1]),:,:], 1);
    center_slice_2 = squeeze(ni_data[:,midpoint(ni_size[2]),:], 2);
    center_slice_3 = squeeze(ni_data[:,:,midpoint(ni_size[3])], 3);

    c = canvasgrid(2,2);
    ops = [:pixelspacing => [1,1]]
    display(c[1,1], center_slice_1; ops...)
    display(c[1,2], center_slice_2; ops...)
    display(c[2,1], center_slice_3; ops...)
end


T1_ni = niread("samples/NC_03_T1.nii");
T1_data = normalize_ni(T1_ni);

# size(ni)

display_brain_centers(T1_data);

mask_ni = niread("samples/NC_03_mask_brain.nii");
masked_data = normalize_ni(mask_ni);

# Mask T1 to only include the brain
T1_masked = T1_data;
T1_masked[masked_data .== 0] = 0;
display_brain_centers(T1_masked);
