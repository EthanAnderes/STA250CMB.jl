
[](
using Weave
weave("gitignore/OnDeck/julia_lecture2/julia_type_design.mdw", plotlib="PyPlot", doctype="github")
)



# Overall Design philosophy: type tree and multiple dispatch

### Every variable has a concrete type

````julia
julia> typeof(4)
Int64

julia> typeof(4.0)
Float64

julia> typeof(4//7)
Rational{Int64}

julia> typeof(rand(101,10))
Array{Float64,2}

julia> typeof([1, 2, 3]) # 1-d array of ints
Array{Int64,1}

````





Function also have a type
````julia
julia> typeof(rand)
Function

````





Types have a type
````julia
julia> typeof(Float64) # convention, types start with capital letter
DataType

julia> typeof(typeof(Float64))
DataType

````







### Typing is not static

````julia
julia> a = 4
4

julia> typeof(a)
Int64

julia> a = 1.0
1.0

julia> typeof(a)
Float64

````







### Besides concrete types, there are abstract types

* Concrete types correspond to a definitive layout in memory (Int16, Int64, Array{Bool, 2})
* Abstract types correspond to a collection or catigory of concrete types.
* For example both Int64 and Float64 are a subtype of Real which is a subtype of Number, etc...
* This gives a whole tree of types.
* Leaf nodes of the tree are concrete types (these types have a specific way they are layed out in memory)
* Parent nodes are abstract types (which don't have a fixed memory layout configuration)
* For example Int16 and Int64 are both of abstract type Real but have different memory layouts



You can move up tree with super
````julia
julia> super(Int64)
Signed

julia> super(Int64) |> super
Integer

julia> super(Int64) |> super |> super
Real

julia> super(Int64) |> super |> super |> super
Number

````





At the top of the tree we have Any
````julia
julia> super(Int64) |> super |> super |> super |> super
Any

````






You can move down the tree with subtypes
````julia
julia> subtypes(AbstractFloat)
4-element Array{Any,1}:
 BigFloat
 Float16 
 Float32 
 Float64 

julia> subtypes(AbstractArray)
19-element Array{Any,1}:
 AbstractSparseArray{Tv,Ti,N}                                                                  
 Base.LinAlg.AbstractTriangular{T,S<:AbstractArray{T,2}}                                       
 Base.LinAlg.HessenbergQ{T,S<:AbstractArray{T,2}}                                              
 Base.LinAlg.QRCompactWYQ{S,M<:AbstractArray{T,2}}                                             
 Base.LinAlg.QRPackedQ{T,S<:AbstractArray{T,2}}                                                
 ⋮                                                                                             
 SubArray{T,N,P<:AbstractArray{T,N},I<:Tuple{Vararg{Union{AbstractArray{T,1},Colon,Int64}}},LD}
 SymTridiagonal{T}                                                                             
 Symmetric{T,S<:AbstractArray{T,2}}                                                            
 Tridiagonal{T}                                                                                

````






Check if a type is an ancestor
````julia
julia> AbstractFloat <: Number
true

julia> AbstractFloat <: AbstractArray
false

````







* You can make user defined types easy too (we'll see that in a second).
* The type system is a bit more exposed in Julia than in matlab
* The reason is multiple dispatch.
* Instead of having the OO style where functions "live" with the objection or types, types and functions are seperated
* To specify the behavor of a function on a new type or object, one can annotate the types of the arguments


I'm defining 4 different versions of foo.
````julia
julia> 
function foo(x::AbstractFloat, y::AbstractFloat)
        println("foo(Float, Float) was called")
        round(Int, x * y)
end
foo (generic function with 1 method)

julia> 
function foo(x::Integer, y::Integer)
        println("foo(Int, Int)  was called")
        x * y
end
foo (generic function with 2 methods)

julia> 
function foo(x, y) # fall back
        println("fall back was called")
        round(Int, x .* y)
end
foo (generic function with 3 methods)

julia> 
function foo(x)
        foo(x, x)
end
foo (generic function with 4 methods)

````







````julia
julia> foo(1, 1)
1

julia> foo(2.0, 1)
2

julia> foo(2.0, 4.9)
10

julia> foo(2.0)
4

julia> foo(randn(15, 15))
15x15 Array{Int64,2}:
 4  1  0  0  0  0  0  0  0  0  1  1  4  9  2
 5  0  3  2  0  1  0  3  2  3  0  1  2  1  0
 0  1  0  2  3  3  0  3  3  2  2  3  0  0  0
 1  0  2  2  0  0  0  2  0  0  2  0  1  0  0
 2  8  0  0  0  0  0  0  0  1  5  0  1  0  1
 ⋮              ⋮              ⋮            
 1  3  0  0  0  0  0  1  1  1  2  6  1  0  0
 1  2  1  1  0  1  1  5  2  0  2  1  6  0  1
 6  0  4  1  2  0  0  1  0  1  4  4  0  1  0
 0  0  0  0  1  1  2  4  1  1  0  1  0  0  0

````







Lists all the possible call signatiures
````julia
julia> methods(foo)
# 4 methods for generic function "foo":
foo(x::AbstractFloat, y::AbstractFloat) at none:3
foo(x::Integer, y::Integer) at none:3
foo(x) at none:3
foo(x, y) at none:3

````








### Just-in-time compilation (JIT)

* When `foo(1, 1)` is called it looks up the type signature of the arguments and decides which function to use
* It also, checks to see if you have called that function with those same type arguments,
* If not it tries to JIT complile it and will save that compiled version for the next time you use it with those same type of arguments


````julia
julia> a = 2
2

````





Warm up Jit compile
```julia
julia> @time foo(a)
foo(Int, Int)  was called
  0.002049 seconds (649 allocations: 36.317 KB)
4
```

Now we are using the Jit
```julia
julia> @time foo(a)
foo(Int, Int)  was called
  0.000039 seconds (15 allocations: 528 bytes)
4
```

* So it is very easy to optimize some functions for different types of arguments.
* but you need to write your code so Julia can infer the types to compile it
* Note: Defining with type anotation like `foo(x::Float64, y::Int)` will be just as fast as `foo(x, y)`. In particular, when foo(Float64, Int) is called, it already knows the types of the arguments and will compile for that type signature.

### Type stability
When functions are not type stable, the JIT doesn't work (as effectively)

The following function is not type stable.
````julia
julia> 
function baz(x)
    cntr = 0        # starts as as int
    for i = 1:length(x)
        if x[i] > 0
            cntr += 1.0 # depending on the run time values  might promote to a float
        end
    end
    cntr
end
baz (generic function with 1 method)

````






This one is type stable
````julia
julia> 
function boo(x)
    cntr = 0.0        # starts as as float
    for i = 1:length(x)
        if x[i] > 0
        	cntr += 1.0 # stays a float
        end
    end
    cntr
end
boo (generic function with 1 method)

````







```julia
julia> a = rand(1_000_000)
1000000-element Array{Float64,1}:
 0.227931

 0.852688
 0.677495
 0.448379
 0.392192
 ⋮
 0.0169363
 0.170113
 0.206248
 0.244891

julia> @time baz(a)
  0.036449 seconds (1.00 M allocations: 15.437 MB)
1.0e6

julia> @time baz(a)
  0.031226 seconds (1.00 M allocations: 15.259 MB, 15.67% gc time)
1.0e6

julia> @time boo(a)
  0.006611 seconds (2.24 k allocations: 111.452 KB)
1.0e6

julia> @time boo(a)
  0.001364 seconds (5 allocations: 176 bytes)
1.0e6
```



### We can look under the hood at the type inference

```julia
julia> @code_warntype baz(a)
Variables:
  x::Array{Float64,1}
  cntr::Any
  #s13::Int64
  i::Int64
  ####fx#1710#8910::Float64

Body:
  begin  # none, line 2:

      cntr = 0 # none, line 3:
      GenSym(2) = (Base.arraylen)(x::Array{Float64,1})::Int64
      GenSym(0) = $(Expr(:new, UnitRange{Int64}, 1, :(((top(getfield))(Base.Intrinsics,:select_value)::I)((Base.sle_int)(1,GenSym(2))::Bo
ol,GenSym(2),(Base.box)(Int64,(Base.sub_int)(1,1)))::Int64)))
      #s13 = (top(getfield))(GenSym(0),:start)::Int64
      unless (Base.box)(Base.Bool,(Base.not_int)(#s13::Int64 === (Base.box)(Base.Int,(Base.add_int)((top(getfield))(GenSym(0),:stop)::Int
64,1))::Bool)) goto 1
      2:
      GenSym(4) = #s13::Int64
      GenSym(5) = (Base.box)(Base.Int,(Base.add_int)(#s13::Int64,1))
      i = GenSym(4)
      #s13 = GenSym(5) # none, line 4:
      GenSym(3) = (Base.arrayref)(x::Array{Float64,1},i::Int64)::Float64
      ####fx#1710#8910 = (Base.box)(Float64,(Base.sitofp)(Float64,0))
      unless (Base.box)(Base.Bool,(Base.or_int)((Base.lt_float)(####fx#1710#8910::Float64,GenSym(3))::Bool,(Base.box)(Base.Bool,(Base.and
_int)((Base.eq_float)(####fx#1710#8910::Float64,GenSym(3))::Bool,(Base.box)(Base.Bool,(Base.or_int)((Base.eq_float)(####fx#1710#8910::Flo
at64,9.223372036854776e18)::Bool,(Base.slt_int)(0,(Base.box)(Int64,(Base.fptosi)(Int64,####fx#1710#8910::Float64)))::Bool)))))) goto 4 #
none, line 5:
      cntr = cntr::Union{Float64,Int64} + 1.0::Float64
      4:
      3:
      unless (Base.box)(Base.Bool,(Base.not_int)((Base.box)(Base.Bool,(Base.not_int)(#s13::Int64 === (Base.box)(Base.Int,(Base.add_int)((
top(getfield))(GenSym(0),:stop)::Int64,1))::Bool)))) goto 2
      1:
      0:  # none, line 8:
      return cntr::Union{Float64,Int64}
	 end::Union{Float64,Int64}
```

Now look at the type inference for `boo`. Notice all the variables have a concrete type.
```julia
julia> @code_warntype boo(a)
Variables:
  x::Array{Float64,1}
  cntr::Float64
  #s13::Int64
  i::Int64
  ####fx#1710#8911::Float64

Body:
  begin  # none, line 2:

      cntr = 0.0 # none, line 3:
      GenSym(2) = (Base.arraylen)(x::Array{Float64,1})::Int64
      GenSym(0) = $(Expr(:new, UnitRange{Int64}, 1, :(((top(getfield))(Base.Intrinsics,:select_value)::I)((Base.sle_int)(1,GenSym(2))::Bo
ol,GenSym(2),(Base.box)(Int64,(Base.sub_int)(1,1)))::Int64)))
      #s13 = (top(getfield))(GenSym(0),:start)::Int64
      unless (Base.box)(Base.Bool,(Base.not_int)(#s13::Int64 === (Base.box)(Base.Int,(Base.add_int)((top(getfield))(GenSym(0),:stop)::Int
64,1))::Bool)) goto 1
      2:
      GenSym(4) = #s13::Int64
      GenSym(5) = (Base.box)(Base.Int,(Base.add_int)(#s13::Int64,1))
      i = GenSym(4)
      #s13 = GenSym(5) # none, line 4:
      GenSym(3) = (Base.arrayref)(x::Array{Float64,1},i::Int64)::Float64
      ####fx#1710#8911 = (Base.box)(Float64,(Base.sitofp)(Float64,0))
      unless (Base.box)(Base.Bool,(Base.or_int)((Base.lt_float)(####fx#1710#8911::Float64,GenSym(3))::Bool,(Base.box)(Base.Bool,(Base.and
_int)((Base.eq_float)(####fx#1710#8911::Float64,GenSym(3))::Bool,(Base.box)(Base.Bool,(Base.or_int)((Base.eq_float)(####fx#1710#8911::Flo
at64,9.223372036854776e18)::Bool,(Base.slt_int)(0,(Base.box)(Int64,(Base.fptosi)(Int64,####fx#1710#8911::Float64)))::Bool)))))) goto 4 #
none, line 5:
      cntr = (Base.box)(Base.Float64,(Base.add_float)(cntr::Float64,1.0))
      4:
      3:
      unless (Base.box)(Base.Bool,(Base.not_int)((Base.box)(Base.Bool,(Base.not_int)(#s13::Int64 === (Base.box)(Base.Int,(Base.add_int)((
top(getfield))(GenSym(0),:stop)::Int64,1))::Bool)))) goto 2
      1:
      0:  # none, line 8:
      return cntr::Float64
  end::Float64
```

### We can really look under the hood at the lowered code, the llvm code and assembly code

For `baz`
````julia
julia> code_lowered(baz, (typeof(a),))
1-element Array{Any,1}:
 :($(Expr(:lambda, Any[:x], Any[Any[Any[:x,:Any,0],Any[:cntr,:Any,2],Any[symbol("#s13"),:Any,2],Any[:i,:Any,18]],Any[],2,Any[]], :(begin  # none, line 3:
        cntr = 0 # none, line 4:
        GenSym(0) = (Weave.ReportSandBox.colon)(1,(Weave.ReportSandBox.length)(x))
        #s13 = (top(start))(GenSym(0))
        unless (top(!))((top(done))(GenSym(0),#s13)) goto 1
        2: 
        GenSym(1) = (top(next))(GenSym(0),#s13)
        i = (top(getfield))(GenSym(1),1)
        #s13 = (top(getfield))(GenSym(1),2) # none, line 5:
        unless (Weave.ReportSandBox.getindex)(x,i) > 0 goto 4 # none, line 6:
        cntr = cntr + 1.0
        4: 
        3: 
        unless (top(!))((top(!))((top(done))(GenSym(0),#s13))) goto 2
        1: 
        0:  # none, line 9:
        return cntr
    end))))

julia> code_llvm(baz, (typeof(a),))

julia> code_native(baz, (typeof(a),))

````




Note in the above code you can also do `@code_lowered boo(a)`, `@code_llvm boo(a)`, `@code_native boo(a)`
but I couldn't get it to print out correctly.


For `boo`
````julia
julia> code_lowered(boo, (typeof(a),))
1-element Array{Any,1}:
 :($(Expr(:lambda, Any[:x], Any[Any[Any[:x,:Any,0],Any[:cntr,:Any,2],Any[symbol("#s13"),:Any,2],Any[:i,:Any,18]],Any[],2,Any[]], :(begin  # none, line 3:
        cntr = 0.0 # none, line 4:
        GenSym(0) = (Weave.ReportSandBox.colon)(1,(Weave.ReportSandBox.length)(x))
        #s13 = (top(start))(GenSym(0))
        unless (top(!))((top(done))(GenSym(0),#s13)) goto 1
        2: 
        GenSym(1) = (top(next))(GenSym(0),#s13)
        i = (top(getfield))(GenSym(1),1)
        #s13 = (top(getfield))(GenSym(1),2) # none, line 5:
        unless (Weave.ReportSandBox.getindex)(x,i) > 0 goto 4 # none, line 6:
        cntr = cntr + 1.0
        4: 
        3: 
        unless (top(!))((top(!))((top(done))(GenSym(0),#s13))) goto 2
        1: 
        0:  # none, line 9:
        return cntr
    end))))

julia> code_llvm(boo, (typeof(a),))

julia> code_native(boo, (typeof(a),))

````







### Julia has been designed, from the groud up, to make type inference easier
`(-1)^(1/2)` gives an error but `(-1+0im)^(1/2)` works (julia wants to be sure that `Int^Float` isn't sometimes complex)

Julia wants to be able to conclude that the return value of `sqrt(Float)` will be a float.

```julia
julia> sqrt(-1.0)
ERROR: DomainError:
sqrt will only return a complex result if called with a complex argument. Try sqrt(complex(x)).
 in sqrt at /Users/ethananderes/Software/julia4/usr/lib/julia/sys.dylib
```

````julia
julia> sqrt(-1.0+0im) # <---- works
0.0 + 1.0im

````




If, instead `sqrt(-1)` returned `im`, then it is impossible to tell if `a = sqrt(b)` will be `Complex{Float64}` or `Float64` when
it is only known that `b` is a Float64. I.e. the type of `a` depends on the run-time value of `b` and not the type of `b`
(which is necessary for compilation).





### Method dispatch in action

* A great example is the Distributions package

````julia
julia> x = rand(10)
10-element Array{Float64,1}:
 0.0962517
 0.665146 
 0.031337 
 0.679928 
 0.567378 
 0.624417 
 0.348078 
 0.643659 
 0.178145 
 0.270182 

julia> mean(x), std(x)  # functions in Base Julia
(0.41045232517670505,0.25435371003593216)

````







````julia
julia> using Distributions

julia> λ, α, β = 5.5, 0.1, 0.9
(5.5,0.1,0.9)

julia> xrv = Beta(α, β) # creats an instance of a Beta random variable
Distributions.Beta(α=0.1, β=0.9)

julia> yrv = Poisson(λ) # creats  an instance of a Poisson
Distributions.Poisson(λ=5.5)

julia> zrv = Poisson(λ) # another instance
Distributions.Poisson(λ=5.5)

julia> typeof(xrv), typeof(yrv), typeof(zrv)
(Distributions.Beta,Distributions.Poisson,Distributions.Poisson)

````






`mean` is overloaded to give the random variable expected value.
````julia
julia> mean(xrv)  # expected value of a Beta(0.1, 0.9)
0.1

````







`std` is overloaded to give the random variable standard deviation
````julia
julia> std(zrv)   # std of a Poisson(5.5)
2.345207879911715

````






`rand` is overloaded to give random samples from yrv
````julia
julia> rand(yrv, 10)  # Poisson(5.5) samples
10-element Array{Int64,1}:
 8
 3
 7
 3
 2
 2
 3
 5
 4
 5

````






Check which method is called
````julia
julia> @which mean(xrv)
mean(d::Distributions.Beta) at /Users/ethananderes/.julia/v0.4/Distributions/src/univariate/continuous/beta.jl:22

````






This will allow you to see the Julia source which was called.
```julia
@edit mean(xrv)
```


If you have Julia source you can go directly to code.
This is particularly useful when debugging (you can read the source to see what is going wrong).
```julia
julia> mean(["hi"])
ERROR: MethodError: `/` has no method matching /(::ASCIIString, ::Int64)
Closest candidates are:
  /(::Integer, ::Integer)
  /(::Complex{T<:Real}, ::Real)
  /(::BigFloat, ::Union{Int16,Int32,Int64,Int8})
  ...
 in mean at statistics.jl:19
```

Lets see where the definition of mean to see what is going wrong
```juila
edit("statistics.jl", 17)
```

# Writing fast code in Julia

* Write most of you code in functions
* Avoid globals (if you must use them, declare as `const` which can not change types)
* Write type stable functions
* Pre allocate arrays and use `for` loops
* Optimize using the profiler


## User defined types and metaprograming

Here is how a user can defined a new type
````julia
julia> type Hmatrix
        frstcol :: Vector{Float64} # field names and optional type annotation
        lastcol :: Vector{Float64} # this is where type annotation is important for speed, want these to be concrete types
end

````







Creat an instance of two Hmatrices. Basic default constructor
````julia
julia> anHmat = Hmatrix([1.0 ,2.0 ,3.0], [5.0 ,6.0, 7.0])
Weave.ReportSandBox.Hmatrix([1.0,2.0,3.0],[5.0,6.0,7.0])

julia> bnHmat = Hmatrix([0.0 ,2.0 ,3.0], [0.0 ,6.0, 7.0])
Weave.ReportSandBox.Hmatrix([0.0,2.0,3.0],[0.0,6.0,7.0])

````








Getting the field values.
````julia
julia> anHmat.frstcol
3-element Array{Float64,1}:
 1.0
 2.0
 3.0

julia> anHmat.lastcol
3-element Array{Float64,1}:
 5.0
 6.0
 7.0

````








Use dispatch to generate other constructors
````julia
julia> Hmatrix(x::Vector{Float64}) = Hmatrix(x, copy(x))
Weave.ReportSandBox.Hmatrix

julia> Hmatrix(x::Float64, d::Int64) = Hmatrix(fill(x,d))
Weave.ReportSandBox.Hmatrix

julia> Heye(d::Int64) = Hmatrix(fill(1.0,d))
Heye (generic function with 1 method)

````







Now I can define operations on Hmatrix.
````julia
julia> import Base: sin, size

julia> sin(h::Hmatrix)  = Hmatrix(sin(h.frstcol), sin(h.lastcol))
sin (generic function with 12 methods)

julia> size(h::Hmatrix) = (length(h.frstcol), length(h.frstcol))
size (generic function with 75 methods)

julia> sin(anHmat)
Weave.ReportSandBox.Hmatrix([0.8414709848078965,0.9092974268256817,0.1411200080598672],[-0.9589242746631385,-0.27941549819892586,0.6569865987187891])

julia> size(anHmat)
(3,3)

````







This gets tedious after a while so I program over the language itself: metaprograming
````julia
julia> import Base: exp, abs, tan, log

julia> for op in [:exp, :abs, :tan, :log]
        quote
                $op(h::Hmatrix) = Hmatrix($op(h.frstcol), $op(h.lastcol))
        end |> eval
end

julia> abs(anHmat)
Weave.ReportSandBox.Hmatrix([1.0,2.0,3.0],[5.0,6.0,7.0])

julia> tan(anHmat)
Weave.ReportSandBox.Hmatrix([1.5574077246549023,-2.185039863261519,-0.1425465430742778],[-3.380515006246586,-0.29100619138474915,0.8714479827243187])

````







Pairwise operations with Hmatrices.
````julia
julia> import Base: .+, .-, .*, ./

julia> for op in [:.+, :.-, :.*, :./]
        quote
                function $op(h::Hmatrix, g::Hmatrix)
                        frstcol = $op(h.frstcol, g.frstcol)
                        lastcol = $op(h.lastcol, g.lastcol)
                        return Hmatrix(frstcol, lastcol)
                end
        end |> eval
end

julia> import Base: *

julia> function *(mat::Matrix, hmat::Hmatrix)
        Hmatrix(mat * hmat.frstcol, mat * hmat.lastcol)
end
* (generic function with 153 methods)

````








A pre-existing function on matrices which only used the above operations will automatically work on Hmatrices.
I encountered this when a new type I had made, just worked on some Runge-Kutta code
````julia
julia> function expmm(mat)
        mat .+ rand(size(mat)) * mat .+ (rand(size(mat)).^2) * mat
end
expmm (generic function with 1 method)

julia> expmm(eye(2))
2x2 Array{Float64,2}:
 1.04533  1.02656
 1.02151  1.85942

julia> expmm(anHmat)
Weave.ReportSandBox.Hmatrix([4.811256679335988,5.414900889041469,6.569048156197742],[17.11599362540062,18.081710059272083,17.523521210990324])

````







I can make indexing work like regular arrays
````julia
julia> import Base: getindex

julia> function getindex(H::Hmatrix, i::Integer, j::Integer)
        siz, _ = size(H)
        if j == 1
                return H.frstcol[i]
        elseif j == siz
                return H.lastcol[i]
        else
                return 0.0
        end
end
getindex (generic function with 157 methods)

julia> anHmat
Weave.ReportSandBox.Hmatrix([1.0,2.0,3.0],[5.0,6.0,7.0])

julia> anHmat[2,3]
6.0

````







Here is a slighly more advanced, version. Take a look at the source code
```julia
@edit Symmetric(rand(3,3))
```


````julia
julia> immutable H2matrix{T} <: AbstractMatrix{T}
        frstcol ::Vector{T}
        lastcol ::Vector{T}
end

````





Defines a whole class of types: `H2matrix{Float64}`, `H2matrix{Int64}`, etc
These are ancestors of `AbstractMatrix{T}`
The fact that they are ancestors of AbstractArrays means that other function will just work.
Moreover you can specialize fast methods if your working with `H2matrix{Uint16}`, for example

I can make indexing work like regular arrays
````julia
julia> import Base: getindex, size, length, sum

julia> size(h::H2matrix) = (length(h.frstcol), length(h.lastcol))
size (generic function with 76 methods)

julia> length(h::H2matrix) = length(h.frstcol)^2
length (generic function with 86 methods)

julia> function getindex{T}(H::H2matrix{T}, i::Integer, j::Integer)
        siz, _ = size(H)
        if j == 1
            return H.frstcol[i]
        elseif j == siz
            return H.lastcol[i]
        else
            return convert(T, 0)
        end
end
getindex (generic function with 158 methods)

````






In the above example, this is an easy way to specialize code based on the element type of H2matrix
````julia
julia> sum(h::H2matrix) = sum(h.frstcol) + sum(h.lastcol)
sum (generic function with 18 methods)

````






Now stuff "Just Works" due to an ancestors of AbstractMatrix{T}
````julia
julia> anH2 = H2matrix(rand(5), rand(5)) # printing is inherited from AbstractMatrix{T}
5x5 Weave.ReportSandBox.H2matrix{Float64}:
 0.778857  0.0  0.0  0.0  0.51954  
 0.766358  0.0  0.0  0.0  0.680816 
 0.276787  0.0  0.0  0.0  0.21632  
 0.924659  0.0  0.0  0.0  0.0166243
 0.488021  0.0  0.0  0.0  0.388994 

````








````julia
julia> anH2 = H2matrix([1,2,3], [3,2,1]) # spcialization for integer
3x3 Weave.ReportSandBox.H2matrix{Int64}:
 1  0  3
 2  0  2
 3  0  1

````






````julia
julia> mean(anH2)
1.3333333333333333

````





How did this work? Check out the source.

```julia
@edit mean(anH2)
```

There is a fallback method for `mean(A::AbstractArray)`` which only uses sum and length.
You can see how important it is to be able read look at Julia source
This wouldn't be possible if it wasn't both fast and readable at the same time
