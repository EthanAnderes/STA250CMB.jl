
[](
using Weave
weave("lectures/julia_lecture2/julia_type_design.mdw", plotlib="PyPlot", doctype="github")
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
 0  1  3  2  0  0  0  0  6  0  1  0  2  0  2
 0  2  2  0  0  2  1  3  0  0  0  0  1  0  2
 0  0  0  2  0  2  0  0  2  0  0  1  1  0  1
 3  0  1  1  3  0  2  3  0  1  1  1  1  0  0
 1  1  2  3  0  0  0  0  1  2  0  0  0  2  0
 ⋮              ⋮              ⋮            
 0  2  0  2  0  0  0  0  2  1  0  1  0  0  0
 0  0  0  0  0  0  0  0  0  1  0  1  0  1  0
 3  2  0  0  0  0  1  0  6  0  0  0  2  0  1
 5  1  0  9  1  2  0  1  3  1  0  0  0  0  1

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
```julia
julia> @code_lowered baz(a)
1-element Array{Any,1}:
 :($(Expr(:lambda, Any[:x], Any[Any[Any[:x,:Any,0],Any[:cntr,:Any,2],Any[symbol("#s4"),:Any,2],Any[:i,:Any,18]],Any[],2,Any[]], :(begin  # none, line 2:
        cntr = 0 # none, line 3:
        GenSym(0) = (Main.colon)(1,(Main.length)(x))
        #s4 = (top(start))(GenSym(0))
        unless (top(!))((top(done))(GenSym(0),#s4)) goto 1
        2:
        GenSym(1) = (top(next))(GenSym(0),#s4)
        i = (top(getfield))(GenSym(1),1)
        #s4 = (top(getfield))(GenSym(1),2) # none, line 4:
        unless (Main.getindex)(x,i) > 0 goto 4 # none, line 5:
        cntr = cntr + 1.0
        4:
        3:
        unless (top(!))((top(!))((top(done))(GenSym(0),#s4))) goto 2
        1:
        0:  # none, line 8:
        return cntr
    end))))
```

```julia
julia> @code_llvm baz(a)

define %jl_value_t* @julia_baz_21597(%jl_value_t*, %jl_value_t**, i32) {
top:
  %3 = alloca [5 x %jl_value_t*], align 8
  %.sub = getelementptr inbounds [5 x %jl_value_t*]* %3, i64 0, i64 0
  %4 = getelementptr [5 x %jl_value_t*]* %3, i64 0, i64 2
  %5 = getelementptr [5 x %jl_value_t*]* %3, i64 0, i64 3
  store %jl_value_t* inttoptr (i64 6 to %jl_value_t*), %jl_value_t** %.sub, align 8
  %6 = load %jl_value_t*** @jl_pgcstack, align 8
  %7 = getelementptr [5 x %jl_value_t*]* %3, i64 0, i64 1
  %.c = bitcast %jl_value_t** %6 to %jl_value_t*
  store %jl_value_t* %.c, %jl_value_t** %7, align 8
  store %jl_value_t** %.sub, %jl_value_t*** @jl_pgcstack, align 8
  store %jl_value_t* null, %jl_value_t** %4, align 8
  store %jl_value_t* null, %jl_value_t** %5, align 8
  %8 = getelementptr [5 x %jl_value_t*]* %3, i64 0, i64 4
  store %jl_value_t* null, %jl_value_t** %8, align 8
  %9 = load %jl_value_t** %1, align 8
  store %jl_value_t* inttoptr (i64 4352729168 to %jl_value_t*), %jl_value_t** %4, align 8
  %10 = getelementptr inbounds %jl_value_t* %9, i64 1
  %11 = bitcast %jl_value_t* %10 to i64*
  %12 = load i64* %11, align 8
  %13 = icmp sgt i64 %12, 0
  %14 = select i1 %13, i64 %12, i64 0
  %15 = icmp eq i64 %14, 0
  br i1 %15, label %L4, label %L.preheader

L.preheader:                                      ; preds = %top
  %16 = bitcast %jl_value_t* %9 to i8**
  br label %L

L:                                                ; preds = %L2, %L.preheader
  %17 = phi %jl_value_t* [ %28, %L2 ], [ inttoptr (i64 4352729168 to %jl_value_t*), %L.preheader ]
  %"#s4.0" = phi i64 [ %29, %L2 ], [ 1, %L.preheader ]
  %18 = add i64 %"#s4.0", -1
  %19 = load i64* %11, align 8
  %20 = icmp ult i64 %18, %19
  br i1 %20, label %idxend, label %oob

oob:                                              ; preds = %L
  %21 = alloca i64, align 8
  store i64 %"#s4.0", i64* %21, align 8
  call void @jl_bounds_error_ints(%jl_value_t* %9, i64* %21, i64 1)
  unreachable

idxend:                                           ; preds = %L
  %22 = load i8** %16, align 8
  %23 = bitcast i8* %22 to double*
  %24 = getelementptr double* %23, i64 %18
  %25 = load double* %24, align 8
  %26 = fcmp ule double %25, 0.000000e+00
  br i1 %26, label %L2, label %if1

if1:                                              ; preds = %idxend
  store %jl_value_t* %17, %jl_value_t** %5, align 8
  store %jl_value_t* inttoptr (i64 4409663568 to %jl_value_t*), %jl_value_t** %8, align 8
  %27 = call %jl_value_t* @jl_apply_generic(%jl_value_t* inttoptr (i64 4362610928 to %jl_value_t*), %jl_value_t** %5, i32 2)
  store %jl_value_t* %27, %jl_value_t** %4, align 8
  br label %L2

L2:                                               ; preds = %if1, %idxend
  %28 = phi %jl_value_t* [ %27, %if1 ], [ %17, %idxend ]
  %29 = add i64 %"#s4.0", 1
  %30 = icmp eq i64 %"#s4.0", %14
  br i1 %30, label %L4, label %L

L4:                                               ; preds = %L2, %top
  %31 = phi %jl_value_t* [ inttoptr (i64 4352729168 to %jl_value_t*), %top ], [ %28, %L2 ]
  %32 = load %jl_value_t** %7, align 8
  %33 = getelementptr inbounds %jl_value_t* %32, i64 0, i32 0
  store %jl_value_t** %33, %jl_value_t*** @jl_pgcstack, align 8
  ret %jl_value_t* %31
}
```


```julia
julia> @code_native baz(a)
	.section	__TEXT,__text,regular,pure_instructions
Filename: none
Source line: 2
	pushq	%rbp
	movq	%rsp, %rbp
Source line: 2
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$40, %rsp
	movq	$6, -80(%rbp)
	movabsq	$jl_pgcstack, %rcx
	movq	(%rcx), %rax
	movq	%rax, -72(%rbp)
	leaq	-80(%rbp), %rax
	movq	%rax, (%rcx)
	vxorpd	%xmm0, %xmm0, %xmm0
	vmovupd	%xmm0, -64(%rbp)
	movq	$0, -48(%rbp)
	movq	(%rsi), %r12
	movabsq	$4352729168, %rax       ## imm = 0x103716050
	xorl	%ebx, %ebx
Source line: 2
	movq	%rax, -64(%rbp)
Source line: 3
	movq	8(%r12), %r13
	testq	%r13, %r13
	movl	$0, %ecx
	cmovnsq	%r13, %rcx
	testq	%rcx, %rcx
	je	L247
Source line: 5
	testq	%r13, %r13
	cmovsq	%rbx, %r13
Source line: 3
	negq	%r13
	movabsq	$4352729168, %rax       ## imm = 0x103716050
Source line: 5
	movabsq	$jl_apply_generic, %r15
	xorl	%r14d, %r14d
Source line: 4
L144:	cmpq	8(%r12), %rbx
	jae	L279
Source line: 5
	leaq	(,%r14,8), %rcx
Source line: 4
	movq	(%r12), %rdx
Source line: 5
	subq	%rcx, %rdx
Source line: 4
	vmovsd	(%rdx), %xmm0
	vxorpd	%xmm1, %xmm1, %xmm1
	vucomisd	%xmm1, %xmm0
	jbe	L232
Source line: 5
	movq	%rax, -56(%rbp)
	movabsq	$4409663568, %rax       ## imm = 0x106D62050
	movq	%rax, -48(%rbp)
	movabsq	$4362610928, %rdi       ## imm = 0x1040828F0
Source line: 2
	leaq	-56(%rbp), %rsi
	movl	$2, %edx
Source line: 5
	callq	*%r15
	movq	%rax, -64(%rbp)
L232:	incq	%rbx
	decq	%r14
	cmpq	%r14, %r13
	jne	L144
Source line: 8
L247:	movq	-72(%rbp), %rcx
Source line: 2
	movabsq	$jl_pgcstack, %rdx
Source line: 8
	movq	%rcx, (%rdx)
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	ret
L279:	movl	$1, %eax
Source line: 4
	subq	%r14, %rax
	movq	%rsp, %rcx
	leaq	-16(%rcx), %rsi
	movq	%rsi, %rsp
	movq	%rax, -16(%rcx)
	movabsq	$jl_bounds_error_ints, %rax
	movq	%r12, %rdi
	movl	$1, %edx
	callq	*%rax
```



For `boo`
```julia
julia> @code_lowered boo(a)
1-element Array{Any,1}:
 :($(Expr(:lambda, Any[:x], Any[Any[Any[:x,:Any,0],Any[:cntr,:Any,2],Any[symbol("#s4"),:Any,2],Any[:i,:Any,18]],Any[],2,Any[]], :(begin  # none, line 2:
        cntr = 0.0 # none, line 3:
        GenSym(0) = (Main.colon)(1,(Main.length)(x))
        #s4 = (top(start))(GenSym(0))
        unless (top(!))((top(done))(GenSym(0),#s4)) goto 1
        2:
        GenSym(1) = (top(next))(GenSym(0),#s4)
        i = (top(getfield))(GenSym(1),1)
        #s4 = (top(getfield))(GenSym(1),2) # none, line 4:
        unless (Main.getindex)(x,i) > 0 goto 4 # none, line 5:
        cntr = cntr + 1.0
        4:
        3:
        unless (top(!))((top(!))((top(done))(GenSym(0),#s4))) goto 2
        1:
        0:  # none, line 8:
        return cntr
    end))))
```


```julia
julia> @code_llvm boo(a)

define double @julia_boo_21605(%jl_value_t*) {
top:
  %1 = getelementptr inbounds %jl_value_t* %0, i64 1
  %2 = bitcast %jl_value_t* %1 to i64*
  %3 = load i64* %2, align 8
  %4 = icmp sgt i64 %3, 0
  %5 = select i1 %4, i64 %3, i64 0
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %L4, label %L.preheader

L.preheader:                                      ; preds = %top
  %7 = load i64* %2, align 8
  %8 = bitcast %jl_value_t* %0 to i8**
  br label %L

L:                                                ; preds = %L2, %L.preheader
  %"#s4.0" = phi i64 [ %18, %L2 ], [ 1, %L.preheader ]
  %cntr.0 = phi double [ %cntr.1, %L2 ], [ 0.000000e+00, %L.preheader ]
  %9 = add i64 %"#s4.0", -1
  %10 = icmp ult i64 %9, %7
  br i1 %10, label %idxend, label %oob

oob:                                              ; preds = %L
  %11 = alloca i64, align 8
  store i64 %"#s4.0", i64* %11, align 8
  call void @jl_bounds_error_ints(%jl_value_t* %0, i64* %11, i64 1)
  unreachable

idxend:                                           ; preds = %L
  %12 = load i8** %8, align 8
  %13 = bitcast i8* %12 to double*
  %14 = getelementptr double* %13, i64 %9
  %15 = load double* %14, align 8
  %16 = fcmp ule double %15, 0.000000e+00
  br i1 %16, label %L2, label %if1

if1:                                              ; preds = %idxend
  %17 = fadd double %cntr.0, 1.000000e+00
  br label %L2

L2:                                               ; preds = %if1, %idxend
  %cntr.1 = phi double [ %cntr.0, %idxend ], [ %17, %if1 ]
  %18 = add i64 %"#s4.0", 1
  %19 = icmp eq i64 %"#s4.0", %5
  br i1 %19, label %L4, label %L

L4:                                               ; preds = %L2, %top
  %cntr.2 = phi double [ 0.000000e+00, %top ], [ %cntr.1, %L2 ]
  ret double %cntr.2
}
```

```julia
julia> @code_native boo(a)
	.section	__TEXT,__text,regular,pure_instructions
Filename: none
Source line: 3
	pushq	%rbp
	movq	%rsp, %rbp
Source line: 3
	movq	8(%rdi), %r9
	xorl	%ecx, %ecx
	testq	%r9, %r9
	movl	$0, %edx
	cmovnsq	%r9, %rdx
	vxorps	%xmm0, %xmm0, %xmm0
	testq	%rdx, %rdx
	je	L129
Source line: 5
	testq	%r9, %r9
	cmovsq	%rcx, %r9
Source line: 3
	negq	%r9
Source line: 4
	movq	8(%rdi), %r8
	vxorpd	%xmm1, %xmm1, %xmm1
	movabsq	$12960071136, %rax      ## imm = 0x3047AFDE0
	vmovsd	(%rax), %xmm2
	xorl	%esi, %esi
	vxorps	%xmm0, %xmm0, %xmm0
L73:	cmpq	%r8, %rcx
	jae	L134
Source line: 5
	leaq	(,%rsi,8), %rdx
Source line: 4
	movq	(%rdi), %rax
Source line: 5
	subq	%rdx, %rax
Source line: 4
	vmovsd	(%rax), %xmm3
	vucomisd	%xmm1, %xmm3
	jbe	L114
Source line: 5
	vaddsd	%xmm2, %xmm0, %xmm0
L114:	incq	%rcx
	decq	%rsi
	cmpq	%rsi, %r9
	jne	L73
Source line: 8
L129:	movq	%rbp, %rsp
	popq	%rbp
	ret
L134:	movl	$1, %eax
Source line: 4
	subq	%rsi, %rax
	movq	%rsp, %rcx
	leaq	-16(%rcx), %rsi
	movq	%rsi, %rsp
	movq	%rax, -16(%rcx)
	movabsq	$jl_bounds_error_ints, %rax
	movl	$1, %edx
	callq	*%rax
```



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
 0.0770753
 0.376324 
 0.695339 
 0.802617 
 0.0543585
 0.549968 
 0.453883 
 0.86412  
 0.575311 
 0.625609 

julia> mean(x), std(x)  # functions in Base Julia
(0.5074604762847319,0.2749933137000953)

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
 5
 6
 8
 7
 2
 3
 6
 7
 8
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
 2.2199    1.5633 
 0.133465  2.41257

julia> expmm(anHmat)
Weave.ReportSandBox.Hmatrix([6.809995595868031,8.473285216321411,6.495295503604809],[22.264488478479493,25.17890065784258,18.38351232398207])

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
 0.0693355  0.0  0.0  0.0  0.781221
 0.701008   0.0  0.0  0.0  0.805297
 0.219444   0.0  0.0  0.0  0.878577
 0.0990448  0.0  0.0  0.0  0.687196
 0.56585    0.0  0.0  0.0  0.194152

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
