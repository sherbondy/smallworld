module Binvox

export write_binvox, view_binvox

# takes a 3d array of binary voxel data and a filename as input
# writes the result as a binvox file
# (code based on: https://github.com/dimatura/binvox-rw-py)
# returns the filename for chaining convenience
function write_binvox(voxel_model::Array{Uint8,3}, fname::String)
    fp = open(fname, "w")

    voxel_model_xzy = permutedims(voxel_model, [1,3,2])

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
    fname
end

function view_binvox(fname)
  run(`viewvox $(fname)`)
end

end
