module Binvox

import Base: display

export write_binvox, view_binvox, display_voxels

typealias VoxelArray Array{Uint8, 3}

# takes a 3d array of binary voxel data and a filename as input
# writes the result as a binvox file
# (code based on: https://github.com/dimatura/binvox-rw-py)
# returns the filename for chaining convenience
function write_binvox(voxel_model::VoxelArray, fname::String)
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


# Fancy IJulia inline voxel plotting code

const three_js = readall(joinpath(dirname(Base.source_path()), "js/three.min.js"))
const voxel_js = readall(joinpath(dirname(Base.source_path()), "js/voxel.js"))
const voxel_scripts = """<script type="text/javascript" charset="utf-8">
                          $(three_js)
                          $(voxel_js)
                         </script>"""

function prepare_display(d::Display)
    display(d, "text/html", voxel_scripts)
end

function prepare_display()
    prepare_display(Base.Multimedia.displays[end])
end


try
    display("text/html", voxel_scripts)
catch
end

canvas_count = 0

function display_voxels(voxel_model::VoxelArray)
  global canvas_count
  canvas_id = "voxel$(canvas_count)"
  display("text/html", """<div id="$(canvas_id)"></canvas>
                          <script charset="utf-8">
                          VoxelGrid("$(canvas_id)", [10,10,10], [0]);
                          </script>""")
  canvas_count += 1
end

end
