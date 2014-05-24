module MRC

# MRC file format conversion functions
# You can find the MRC specification here:
# http://www2.mrc-lmb.cam.ac.uk/research/locally-developed-software/image-processing-software/#image

export readMRCfile

# just trying things out
# comments
for x in ARGS
  println(x)
end

# calling c libraries!
t = ccall( (:clock, "libc"), Int32, ())
println("The time is $t")

# okay, here we go, buddy.
# the real diehl

# overengineering party!
immutable MRCMode
  val::Int
end

# S is for signed
S8BitMode = MRCMode(0)
S16BitMode = MRCMode(1)
S32BitMode = MRCMode(2)
# C is for complex, like humans!
C16BitMode = MRCMode(3)
C32BitMode = MRCMode(4)
# U is for unsigned!
U16BitMode = MRCMode(6)

# modeled after the MATLAB code here:
# http://ami.scripps.edu/software/mrctools/mrc_specification.php

function readMRCfile(fname)
  # readMRCfile readMRCfile (fname)
  s = open(fname, "r")

  # oh man... is SO cool! splat!
  dims = read(s, Int32, 3)
  println("nx,ny,nz = $dims")

  mode_val::Int = read(s, Int32)
  mode = MRCMode(mode_val)
  println("mode = $mode")

  # seek to start of data
  seek(s, 1024)

  if mode == S32BitMode
    println("OH YEAH")
    a = read(s, Float32, dims...)
  end

  close(s)
  return a
end

readMRCfile("samples/chlamydomonas_axoneme.mrc")

# if fid == -1
#     error('can''t open file');
#     a= -1;
#     return;
# end
# nx=fread(fid,1,'long');
# ny=fread(fid,1,'long');
# nz=fread(fid,1,'long');
# type= fread(fid,1,'long');
# fprintf(1,'nx= %d ny= %d nz= %d type= %d', nx, ny,nz,type);
# % Seek to start of data
# status=fseek(fid,1024,-1);
# % Shorts
# if type== 1
#     a=fread(fid,nx*ny*nz,'int16');
# end
# %floats
# if type == 2
#     a=fread(fid,nx*ny*nz,'float32');
# end
# fclose( fid);
# a= reshape(a, [nx ny nz]);
# if nz == 1
#     a= reshape(a, [nx ny]);
# end
