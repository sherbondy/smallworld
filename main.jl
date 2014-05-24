using NIfTI
using ImageView, Images

function midpoint(val)
    convert(Int, val/2 + 1)
end

T1_ni = niread("samples/NC_03_T1.nii");
T1_data = T1_ni.raw
T1_data -= minimum(T1_data)
T1_data /= maximum(T1_data)
# size(ni)
T1_size = size(T1_data)
center_slice_1 = squeeze(T1_data[get_midpoint(T1_size[1]),:,:], 1);
center_slice_2 = squeeze(T1_data[:,get_midpoint(T1_size[2]),:], 2);
center_slice_3 = squeeze(T1_data[:,:,get_midpoint(T1_size[3])], 3);

c = canvasgrid(2,2);
ops = [:pixelspacing => [1,1]]
display(c[1,1], center_slice_1; ops...)
display(c[1,21], center_slice_2; ops...)
display(c[2,1], center_slice_3; ops...)
