using NIfTI
using ImageView, Images
using DataFrames
using Gadfly
using Meshes

function midpoint(val)
    convert(Int, val/2 + 1)
end

function normalized_niread(fname)
    ni_data = niread(fname);
    raw = ni_data.raw
    raw_norm = raw - minimum(raw)
    raw_norm /= maximum(raw_norm)
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
    imgc, imgslice = display(c[2,1], center_slice_3; ops...)
    return imgc
end


T1_data = normalized_niread("samples/NC_03_T1.nii");

# size(T1_data)

display_brain_centers(T1_data);

brain_mask_data = normalized_niread("samples/NC_03_mask_brain.nii");

function masked_brain(brain_data, mask_data)
    brain_masked = copy(brain_data);
    brain_masked[mask_data .== 0] = 0;
    brain_masked
end

# Mask T1 to only include the brain
T1_brain_masked = masked_brain(T1_data, brain_mask_data);
canvas = display_brain_centers(T1_brain_masked);

##If we are not in a REPL
#if (!isinteractive())
#    # Create a condition object
#    c = Condition()
#    # Get the main window (A Tk toplevel object)
#    win = toplevel(canvas)
#    # Notify the condition object when the window closes
#    bind(win, "<Destroy>", e->notify(c))
#    # Wait for the notification before proceeding ...
#    wait(c)
#end

# convert voxel data to 1d array with 0-vales removed
function nonzero_1d_data(voxel_data)
    data_1d = vec(voxel_data);
    nonzero_data = filter((x)-> x > 0, data_1d);
    # we seemingly need Float64s to make Gadfly happy
    data_float64 = map((x)-> convert(Float64, x), nonzero_data);
end

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

function nonzero_overlay_histogram(brains, labels)
    # takes a {} vector of mri data vectors
    # and a tuple/vector of corresponding labels as inputs
    all_intensities = []
    all_labels = []
    for i = 1:length(labels)
        brain_1d = nonzero_1d_data(brains[i]);
        all_intensities = vcat(all_intensities, brain_1d)
        all_labels = vcat(all_labels, [labels[i] for _ in brain_1d])
    end

    df = DataFrame(Intensity = all_intensities, Label = all_labels)
    plot(df, x="Intensity", color="Label",
         Geom.histogram(bincount=10),
         Guide.xlabel("Intensity"), Guide.ylabel("Voxel Count"))
end

p_t1 = nonzero_overlay_histogram(T1_masked_brains, mask_titles)


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

t2_csf = T2_masked_brains[3];
t2_nonzero_csf = nonzero_1d_data(t2_csf);
plot(x=t2_nonzero_csf, Geom.histogram(bincount=10));

#let's try and put some numbers to how t2 csf looks!
#mean(t2_nonzero_csf)
#median(t2_nonzero_csf)
#std(t2_nonzero_csf)

t2_size = size(T2_data);
ventricle_mask = zeros(Uint8, t2_size[1], t2_size[2], t2_size[3]);
ventricle_mask[T2_data .> 0.6] = 1;

function write_binvox(voxel_model, fname)
    # takes a 3d array of binary voxel data and a filename as input
    fp = open(fname, "w")

    voxel_model_xzy = permutedims(voxel_model, [1,3,2]);

    vsize = size(voxel_model_xzy)
    voxels_flat = vec(voxel_model_xzy)

    write(fp, "#binvox 1\n")
    write(fp, "dim $(vsize[1]) $(vsize[2]) $(vsize[3])\n")
    write(fp, "translate 0 0 0\n")
    write(fp, "scale 1\n")
    write(fp, "data\n")

    state = voxels_flat[1]
    ctr = 0
    for c in voxels_flat
        if c == state
            ctr += 1
            if ctr == 255
                write(fp, uint8(state))
                write(fp, uint8(ctr))
                ctr = 0
            end
        else
            write(fp, uint8(state))
            write(fp, uint8(ctr))
            state = c
            ctr = 1
        end
    end
    if ctr > 0
        write(fp, uint8(state))
        write(fp, uint8(ctr))
    end

    close(fp)
end

#test_cube = ones(Uint8, 64, 64, 64)
#make a file from ventricle_mask, then call viewvox
write_binvox(ventricle_mask, "ventricle.binvox");
#run(`./viewvox ventricle1.binvox`)

#I should make a dataframe with columns for intensity and mask type
#Then plot x="Intensity", color="Mask"

T1_masked_im = grayim(T1_masked);
#erode(T1_masked_im)
#dilate(T1_masked_im)
#label_components(T1_masked_im)...

#opening = erode -> dilate
opened_mask = opening(ventricle_mask);
write_binvox(opened_mask, "opened.binvox");

# include neighbors and diagonals in connectivity check
binary_opened_mask = convert(BitArray, opened_mask);

connectivity = trues(3,3,3);
connected_components = label_components(binary_opened_mask, connectivity);
region_count = maximum(connected_components);
edges, region_counts = hist(vec(connected_components), 1:13);

sorted_regions = sort(region_counts, rev=true);

# the two largest regions should correspond to the ventricles!
first_region = findfirst(region_counts, sorted_regions[1]);
second_region = findfirst(region_counts, sorted_regions[2]);

refined_ventricle_mask = zeros(Uint8, t2_size[1], t2_size[2], t2_size[3]);
refined_ventricle_mask[connected_components .== first_region] = 1;
refined_ventricle_mask[connected_components .== second_region] = 1;

#mesh = isosurface(binary_brain_mask, 0x01, 0x00);
#exportToStl(mesh, "test.stl");
