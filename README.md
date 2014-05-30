#Julia for Educational Scientific Computing

Here I demonstrate that Julia is already capable of performing all of the
functionality necessary for the Machine Vision unit of MIT's
[6.S02](http://www.eecs.mit.edu/academics-admissions/academic-information/subject-updates-st-2013/6s02) course.

This is a fully-operational port of Machine Vision Lab 1 from Spring 2014.

You can get started by doing the following:

1. Install Julia 0.2 from http://julialang.org.
2. Clone this project to your computer:

```
git clone http://github.com/sherbondy/smallworld
```

3. In the `smallworld` directory, start up Julia:

```
julia
> Pkg.resolve()
```

`Pkg.resove()` will grab all of the project dependencies.

4. If you don't already have IPython installed, you should [grab it](http://ipython.org/install.html)

5. Now you can launch an IJulia notebook:

```
ipython notebook --profile=julia
```

6. You can optionally install a standalone desktop voxel viewer (`viewvox`) from
[http://www.cs.princeton.edu/~min/viewvox/](the viewvox webpage) if my WebGL
viewer runs slowly in your browser.
