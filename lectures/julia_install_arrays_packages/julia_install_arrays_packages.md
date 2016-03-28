
[](weave("lectures/julia_install_arrays_packages/julia_install_arrays_packages.mdw", plotlib="PyPlot", doctype="github")


#  Why I'm excited about Julia

* Open source
* High level matlab-like syntax
* Fast like C (often one can get within a factor of 2 of C)
* Made for scientific computing (matrices first class, linear algebra support, native fft ...)
* Modern features like:
  - Macros,
  - closures,
  - pass by reference,
  - OO qualities,
  - modules
  - code can be written in Unicode ( I'll never write sqrt(2) again. instead √(2) )
  - parallelism and distributed computation
  - powerful shell programming
  - named and optional arguments
  - julia notebooks
* I can finally write fast loops (not to be underestaimted)
* Since it is fast most of julia is written in julia
* Since it is high level, the source is actually readable (and a good way to learn)
* Julia interacts with python so well, any of the missing functionality can be called out to python



Installation
=============================================

There are three ways to install Julia: compile from source, download the binaries, use [homebrew](http://brew.sh).


### Compile from source
I compile Julia from source and usually put it in a directory called `Software`. You will first need to make sure you have the command line arguments installed (if your on a mac). First download X-code from the mac store and then enter `xcode-select --install` at the terminal. Now you need up-to-date gcc (and other stuff). I use homebrew for this.
```
brew install gcc
brew install Caskroom/cask/xquartz
brew install cmake
```
Once these are installed I do the following
```
cd Software
git clone -b release-0.4 git://github.com/JuliaLang/julia.git julia4
cd julia4
make
```
If this works, add `export PATH="/Users/ethananderes/Software/julia4/:$PATH"` (with `/Users/ethananderes` replaced by the path on your machine) to your `.bash_profile` and you should be able to call `julia` from the terminal.


### Download binaries
Probably the easiest way to install the Julia binaries is with homebrew (follow instructions [here](https://github.com/staticfloat/homebrew-julia/)).

If you don't want to use homebrew, you can download the binaries directly from [julialang.com](julialang.com) but you will need to add the path to Julia in your `.bash_profile` if you do it that way.


### Getting help

The documentation found at [julialang.com](julialang.com) is pretty good. You can also ask questions on Google groups (search julia). The Julia community is pretty friendly and they welcome beginners so don't hesitate to ask for help.






Python
=============================================
Most of the code you will write in this class will be in Julia. However, Physicists traditionally use python for all their data analysis so we will need to call some of the python modules written specifically for CMB analysis. Lucky python and Julia work amazing well together so this will not be a problem. If you already have python working (and have numpy, matplotlib, etc installed and working) then your already ready to go. If not, then I recommend installing anaconda which will automatically install everything we need.

To install Anaconda I recommend using the command-line installer (instructions [here](https://www.continuum.io/downloads)).

Once Anaconda is installed you can add packages using something like `conda install ...` for packages registered with conda. If you want to install a package not registered with conda you can do something like the following example (to install Pweave in python)
```
conda config --add channels mpastell
conda install pweave
```

If, at any time, you need to update Anaconda just enter the following at the terminal.
```
conda update conda
conda update anaconda
```



Julia basics
=======================================

Using Julia as a calculator.
````julia
julia> a = 1 + sin(2)
1.9092974268256817

julia> b = besselj(2, a ^ 2)
0.4376457719304935

julia> d = sin(a * b * π)
0.49383153154679066

````


![](figures/julia_install_arrays_packages_1_1.png)




Shell mode, help mode and namesapce variables
```
shell>  pwd
/Users/ethananderes/Dropbox/Courses

shell>  cd ..
/Users/ethananderes/Dropbox

help?>  besselj
search: besselj besseljx besselj1 besselj0 bessely besselk besseli besselh besselyx bessely1 bessely0 besselkx besselix besselhx


julia> whos() # variables in my namespace
```


Run a file of Julia source
```julia
include("run.jl")
```

Exit REPL and quit
```
quit()
```

To uninstall Julia, just remove binaries (this should just be one directory) and `~/.julia/`.






Intro to multidimensional arrays
=======================================
In this class you will mostly work with multidimensional arrays. These are lightweight mutable containers.


Here are a few ways to construct arrays
````julia
julia> vec1 = [1, 2, 3]  # a list (i.e. vector)
3-element Array{Int64,1}:
 1
 2
 3

julia> mat1 = [1.1 2.0 3; 4 5 6] # a matrix.
2x3 Array{Float64,2}:
 1.1  2.0  3.0
 4.0  5.0  6.0

julia> mat2 = randn(3,4)  # a matrix with N(0,1) entries.
3x4 Array{Float64,2}:
  0.207744  -0.505923   -1.01331    1.18486
 -0.496404  -0.0290163   0.303663  -1.02236
 -1.54354   -0.547974   -1.66146   -1.87705

julia> mat3 = zeros(2,2,2)  # a 2x2x2 multidimentional array
2x2x2 Array{Float64,3}:
[:, :, 1] =
 0.0  0.0
 0.0  0.0

[:, :, 2] =
 0.0  0.0
 0.0  0.0

julia> mat4 = eye(5)  #<--- 5 x 5 idenity matrix
5x5 Array{Float64,2}:
 1.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0
 0.0  0.0  0.0  0.0  1.0

````







Accessing submatrices and elements of an array.
````julia
julia> row   = [1  2  4  6]  # rows are two dimensional
1x4 Array{Int64,2}:
 1  2  4  6

julia> mat2[1, 2] # first row, second column
-0.5059229769554402

julia> mat2[1, :] # first row
1x4 Array{Float64,2}:
 0.207744  -0.505923  -1.01331  1.18486

julia> mat2[:, 2] # second column...trailing degenerate dimensions are removed
3-element Array{Float64,1}:
 -0.505923 
 -0.0290163
 -0.547974 

julia> mat2[1:3, 7:end] # matrix sub block
3x0 Array{Float64,2}

julia> mat2[:]  # stacks the columns
12-element Array{Float64,1}:
  0.207744 
 -0.496404 
 -1.54354  
 -0.505923 
 -0.0290163
  ⋮        
  0.303663 
 -1.66146  
  1.18486  
 -1.02236  
 -1.87705  

````






Arrays are mutable so you can allocate them and fill in their entries
````julia
julia> mat5 = Array(Float64, 2,3)  # allocate a 2x3 array with Float64 entries
2x3 Array{Float64,2}:
 4.24399e-314  0.0  2.19807e-314
 1.061e-314    0.0  2.23895e-314

julia> mat5[1,2] = 0  # change the 1,2 entry to 0.0
0

julia> mat5[5] = 1000 # change the 5th entry (in column major ordering)
1000

julia> mat5
2x3 Array{Float64,2}:
 4.24399e-314  0.0  1000.0         
 1.061e-314    0.0     2.23895e-314

julia> mat5[:,1] = 22 # change everything in first column to 22 and supress output
22

julia> mat5
2x3 Array{Float64,2}:
 22.0  0.0  1000.0         
 22.0  0.0     2.23895e-314

julia> mat5[:]   = rand(2,3)  # replace all entries of mat5 with U(0,1) entries
2x3 Array{Float64,2}:
 0.254848  0.366316  0.771549
 0.590788  0.132704  0.196627

````







Vectorize operations
````julia
julia> mat1 = eye(2)
2x2 Array{Float64,2}:
 1.0  0.0
 0.0  1.0

julia> mat2 = randn(2,2)
2x2 Array{Float64,2}:
 -1.38098  0.900008
  1.16352  1.2803  

julia> mat2 .^ 2 # .^ is coordinstewise power
2x2 Array{Float64,2}:
 1.90712  0.810014
 1.35377  1.63916 

julia> exp(mat2)
2x2 Array{Float64,2}:
 0.251331  2.45962
 3.20117   3.59771

julia> mat1 .* mat2
2x2 Array{Float64,2}:
 -1.38098  0.0   
  0.0      1.2803

julia> mat2 .<= 0
2x2 BitArray{2}:
  true  false
 false  false

julia> mat1 .<= mat2
2x2 BitArray{2}:
 false  true
  true  true

````





Finding and changing elements
````julia
julia> mat2[mat2 .<= mat1] = -1
-1

julia> mat2
2x2 Array{Float64,2}:
 -1.0      0.900008
  1.16352  1.2803  

julia> find(mat2 .≥ 0) # returns a vector of linear column-wise indices
3-element Array{Int64,1}:
 2
 3
 4

````






Built in linear algebra (from BLAS and LPACK)
````julia
julia> mat2 = rand(3,3)
3x3 Array{Float64,2}:
 0.26007   0.162725  0.142675
 0.774435  0.146265  0.383884
 0.724349  0.109381  0.375491

julia> mat2 = mat2 * mat2.' # matrix multiplication
3x3 Array{Float64,2}:
 0.114472  0.279979  0.259754
 0.279979  0.768511  0.721106
 0.259754  0.721106  0.67764 

julia> d, v = eig(mat2)
([0.00014932990712749123,0.013074035627661297,1.5473992461600308],
3x3 Array{Float64,2}:
  0.167992   0.951554   -0.257535
 -0.706458  -0.0659954  -0.704671
  0.687529  -0.300316   -0.661146)

julia> u  = chol(mat2)
3x3 UpperTriangular{Float64,Array{Float64,2}}:
 0.338337  0.827515  0.767736 
 0.0       0.289361  0.296489 
 0.0       0.0       0.0177538

julia> l  = chol(mat2, Val{:L})
3x3 LowerTriangular{Float64,Array{Float64,2}}:
 0.338337  0.0       0.0      
 0.827515  0.289361  0.0      
 0.767736  0.296489  0.0177538

````









Julia packages
=======================================


Packages in Julia are hosted on github. These are saved in `~/.julia/`. Download a package with:
```julia
Pkg.add("Distributions")
```
This only needs to be done once. Loading a package into a session is done with `using`.
```julia
using Distributions
rand(Beta(1/2, 1/2), 10) # from the Distributions package
```
Note that in the above code, the `rand` function is overloaded by `Distributions`.


### Ploting with matplotlib using PyPlot


````julia
julia> using PyPlot

julia> x = sin(1 ./ linspace(.05, 0.5, 1_000))
1000-element Array{Float64,1}:
 0.912945
 0.825943
 0.714887
 0.58439 
 0.439275
 ⋮       
 0.906264
 0.907029
 0.907789
 0.908545
 0.909297

julia> plot(x, "r--")
1-element Array{Any,1}:
 PyObject <matplotlib.lines.Line2D object at 0x32a50ce90>

julia> title("My Plot")
PyObject <matplotlib.text.Text object at 0x3298c8b10>

julia> ylabel("red curve")
PyObject <matplotlib.text.Text object at 0x3260cd750>

````


![](figures/julia_install_arrays_packages_8_1.png)






````julia
julia> imshow(rand(100,100))
PyObject <matplotlib.image.AxesImage object at 0x32b067210>

````


![](figures/julia_install_arrays_packages_9_1.png)





### Using PyCall for missing libraries

````julia
julia> using PyCall

julia> @pyimport scipy.interpolate as scii

julia> x = 1:10
1:10

julia> y = sin(x) + rand(10)/5
10-element Array{Float64,1}:
  0.879096
  0.924553
  0.295846
 -0.603455
 -0.898748
 -0.169629
  0.756104
  1.18645 
  0.582592
 -0.42786 

julia> iy = scii.UnivariateSpline(x, y, s = 0) # python object
PyObject <scipy.interpolate.fitpack2.InterpolatedUnivariateSpline object at 0x32b0a6290>

````





Here is all the stuff in iy
````julia
julia> [println(k) for k in keys(iy)];
36-element Array{Any,1}:
 nothing
 nothing
 nothing
 nothing
 nothing
 ⋮      
 nothing
 nothing
 nothing
 nothing
 nothing

````






We want the field that gives us the spline function
````julia
julia> iy[:__call__]
PyObject <bound method InterpolatedUnivariateSpline.__call__ of <scipy.interpolate.fitpack2.InterpolatedUnivariateSpline object at 0x32b0a6290>>

````







````julia
julia> yinterp(x) = iy[:__call__](x) # pull out the function part of iy
yinterp (generic function with 1 method)

julia> xnew = linspace(2, 9, 1000)
linspace(2.0,9.0,1000)

julia> plot(xnew, yinterp(xnew))
1-element Array{Any,1}:
 PyObject <matplotlib.lines.Line2D object at 0x32b110a90>

julia> plot(x, y,"r*")
1-element Array{Any,1}:
 PyObject <matplotlib.lines.Line2D object at 0x32b110c90>

````


![](figures/julia_install_arrays_packages_13_1.png)






### Distributions package



x = rand(10)
mean(x), std(x)  # functions in Base Julia
<<term=true>>=





<<term=true>>=
using Distributions
λ, α, β = 5.5, 0.1, 0.9
xrv = Beta(α, β) # creats an instance of a Beta random variable
yrv = Poisson(λ) # creats  an instance of a Poisson
zrv = Poisson(λ) # another instance
typeof(xrv), typeof(yrv), typeof(zrv)
<<term=true>>=




<<term=true>>=
# mean is overloaded to give the random variable expected value.
mean(xrv)  # expected value of a Beta(0.1, 0.9)
<<term=true>>=



<<term=true>>=
# std is overloaded to give the random variable standard deviation
std(zrv)   # std of a Poisson(5.5)
<<term=true>>=


<<term=true>>=
# rand is overloaded to give random samples from yrv
rand(yrv, 10)  # Poisson(5.5) samples
<<term=true>>=



<<term=true>>=
@which mean(xrv) # check which method is called
<<term=true>>=



```julia
@edit mean(xrv)
```


```julia
# If you have Julia source you can go directly to code
# This is particularly useful when debugging (you can read the source to see what is going wrong)
mean(["hi"])
```

```julia
# Lets see where the definition of mean to see what is going wrong
edit("statistics.jl", 17)
```
