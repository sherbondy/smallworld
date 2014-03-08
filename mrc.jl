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

# http://ami.scripps.edu/software/mrctools/mrc_specification.php
# function readMRCfile(fname)
# # readMRCfile readMRCfile (fname)
# [fid,message]=fopen(fname,'r');
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
