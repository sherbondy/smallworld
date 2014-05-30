# this is intended to be run interactively!
using Binvox
using NIfTI
using ImageView, Images
using DataFrames
using Gadfly
using Meshes

## HELPER FUNCTIONS

function midpoint(val)
    convert(Int, val/2 + 1)
end

function normalized_niread(fname)
    ni_data = niread(fname);
    raw = ni_data.raw
    raw_norm = raw - minimum(raw)
    raw_norm /= maximum(raw_norm)
end

# display three side-by-side images of the center slices from a volume
function display_brain_centers(ni_data)
    ni_size = size(ni_data)
    center_slice_1 = squeeze(ni_data[midpoint(ni_size[1]),:,:], 1);
    center_slice_2 = squeeze(ni_data[:,midpoint(ni_size[2]),:], 2);
    center_slice_3 = squeeze(ni_data[:,:,midpoint(ni_size[3])], 3);

    c = canvasgrid(2,2);
    ops = [:pixelspacing => [1,1]]
    display(c[1,1], center_slice_1; ops...)
    display(c[1,2], center_slice_2; ops...)
    imgc, imgslice = display(c[2,1], center_slice_3; ops...)
    return imgc
end

# mask a volume with the provided mask, returning a new volume
function masked_brain(brain_data, mask_data)
    brain_masked = copy(brain_data);
    brain_masked[mask_data .== 0] = 0;
    brain_masked
end

# convert voxel data to 1d array with 0-vales removed
function nonzero_1d_data(voxel_data)
    data_1d = vec(voxel_data);
    nonzero_data = filter((x)-> x > 0, data_1d);
    # we seemingly need Float64s to make Gadfly happy
    data_float64 = map((x)-> convert(Float64, x), nonzero_data);
end

# takes a {} vector of mri data vectors
# and a tuple/vector of corresponding labels as inputs
# outputs a Gadfly plot with a histogram overlay of
# the different brain intensity values
function nonzero_overlay_histogram(brains, labels, bincount=10)
    all_intensities = []
    all_labels = []
    for i = 1:length(labels)
        brain_1d = nonzero_1d_data(brains[i]);
        all_intensities = vcat(all_intensities, brain_1d)
        all_labels = vcat(all_labels, [labels[i] for _ in brain_1d])
    end

    df = DataFrame(Intensity = all_intensities, Label = all_labels)
    plot(df, x="Intensity", color="Label",
         Geom.histogram(bincount=bincount),
         Guide.xlabel("Intensity"), Guide.ylabel("Voxel Count"))
end




##
## THE ACTUAL INTERACTIVE SESSION FOLLOWS:
##

T1_data = normalized_niread("samples/NC_03_T1.nii");

# size(T1_data)

display_brain_centers(T1_data);

brain_mask_data = convert(Array{Uint8}, normalized_niread("samples/NC_03_mask_brain.nii"));

# Mask T1 to only include the brain
T1_brain_masked = masked_brain(T1_data, brain_mask_data);
display_brain_centers(T1_brain_masked);


T1_brain_1D = nonzero_1d_data(T1_brain_masked);

# feel free to play with different bin counts...
p = plot(x=T1_brain_1D, Geom.histogram(bincount=10),
         Guide.xlabel("Intensity"), Guide.ylabel("Voxel Count"));
#draw(PNG("t1_hist.png", 6inch, 3inch), p);

gm_mask_data = normalized_niread("samples/NC_03_mask_GM.nii");
wm_mask_data = normalized_niread("samples/NC_03_mask_WM.nii");
csf_mask_data = normalized_niread("samples/NC_03_mask_CSF.nii");

mask_titles = ("GM", "WM", "CSF");
mask_array = {gm_mask_data, wm_mask_data, csf_mask_data};

T1_masked_brains = map((mask_data)-> masked_brain(T1_data, mask_data),
                       mask_array);

p_t1 = nonzero_overlay_histogram(T1_masked_brains, mask_titles)

#example of an interactive image (grey matter from T1)
T1_masked_im = grayim(T1_masked_brains[1]);
display(T1_masked_im, pixelspacing=[1,1])

#T2

T2_data = normalized_niread("samples/NC_03_T2.nii");
T2_masked_brains = map((mask_data)-> masked_brain(T2_data, mask_data),
                       mask_array);

p_t2 = nonzero_overlay_histogram(T2_masked_brains, mask_titles)


#FLAIR

FLAIR_data = normalized_niread("samples/NC_03_FLAIR.nii");
FLAIR_masked_brains = map((mask_data)-> masked_brain(FLAIR_data, mask_data),
                          mask_array);

p_flair = nonzero_overlay_histogram(FLAIR_masked_brains, mask_titles)


# Now that we've tried all three image types, let's take a closer look
# at the T2 CSF data...
t2_csf = T2_masked_brains[3];
t2_nonzero_csf = nonzero_1d_data(t2_csf);
plot(x=t2_nonzero_csf, Geom.histogram(bincount=10));

#let's try and put some numbers to how t2 csf looks!
#mean(t2_nonzero_csf)
#median(t2_nonzero_csf)
#std(t2_nonzero_csf)

t2_size = size(T2_data);
#prepare an empty voxel grid to place the ventricle volume
ventricle_mask = zeros(Uint8, t2_size[1], t2_size[2], t2_size[3]);
# 0.6 seems like a decent intensity threshold for isolating CSF:
ventricle_mask[T2_data .> 0.6] = 1;

#make a file from ventricle_mask:
write_binvox(ventricle_mask, "ventricle.binvox");
#then call viewvox:
#view_binvox('ventricle1.binvox')

#opening(x) = dilate(erode(x))
opened_mask = opening(ventricle_mask);
write_binvox(opened_mask, "opened.binvox");

# include neighbors and diagonals in connectivity check
binary_opened_mask = convert(BitArray, opened_mask);

connectivity = trues(3,3,3);
connected_components = label_components(binary_opened_mask, connectivity);
region_count = maximum(connected_components);
edges, region_counts = hist(vec(connected_components), 1:region_count);

sorted_regions = sort(region_counts, rev=true);

# the two largest regions should correspond to the ventricles!
# aww, shucks, it turns on that the first one was bogus, so we use 2 and 3...
first_region = findfirst(region_counts, sorted_regions[2]);
second_region = findfirst(region_counts, sorted_regions[3]);

refined_ventricle_mask = zeros(Uint8, t2_size[1], t2_size[2], t2_size[3]);
refined_ventricle_mask[connected_components .== first_region] = 1;
refined_ventricle_mask[connected_components .== second_region] = 1;

# now we can subtract the ventricles from the original brain mask
hollowed_brain = brain_mask_data - refined_ventricle_mask;
write_binvox(hollowed_brain, "hollowed_brain.binvox");

write_binvox(refined_ventricle_mask, "ventricle_refined.binvox");

mesh = isosurface(hollowed_brain, 0x01, 0x00);
exportToStl(mesh, "hollowed_brain.stl");
