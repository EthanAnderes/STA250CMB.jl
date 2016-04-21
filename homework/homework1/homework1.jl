# code to generate exercise1.jl

using PyPlot, HDF5

# --- set the seed
seedstart = 0xb70099b10363c8e1 # rand(UInt64)
srand(seedstart)


# Covariance functions
cov1(x,y) = exp(-norm(x-y))
cov2(x,y) = (norm(x)^0.85 + norm(y).^0.85 - norm(x-y).^0.85)
function cov3(x,y)
	ν    = 1.2
	ρ    = 0.01
	σ²   = 1.0
	arg  = √(2ν/ρ) * norm(x-y)
	if arg == 0.0
		return σ²
	else
		rtn  = arg^ν
		rtn *= besselk(ν, arg)
		rtn *= σ² * 2^(1-ν) / gamma(ν)
		return rtn
	end
end

cov(x,y) = cov3(x,y)

#=###############################

 One dimensional simulation

=###############################
n         = 50       # <-- number of observation locations
x1d_obs   = sort(rand(n))   # <-- observation locations
Σ         = Float64[cov(xi,yi) for xi in x1d_obs, yi in x1d_obs]
Σobs      = Σ +  (0.15)^2 * eye(n)
chlΣobs   = chol(Σobs, Val{:L})
fx1d_obs  = chlΣobs * randn(n)
#=
plot(x1d_obs, fx1d_obs, "r.", label="obs with noise")
=#


# --- now compute the conditinal expected value, conditional variance and conditional simulations on x1d_pre
x1d_pre    = linspace(-.1, 1.1, 200)
Σcross     = Float64[cov(xi,yi) for xi in x1d_pre, yi in x1d_obs]
Σpre       = Float64[cov(xi,yi) for xi in x1d_pre, yi in x1d_pre]
μ_fx1d_pre =  Σcross * (Σobs \ fx1d_obs)
Σ_fx1d_pre =  Σpre -  Σcross * (Σobs \ transpose(Σcross))
#=
plot(x1d_obs, fx1d_obs, "r.", label="obs with noise")
plot(x1d_pre, μ_fx1d_pre, "g", label="predicted")
fill_between(x1d_pre,
	μ_fx1d_pre - √(diag(Σ_fx1d_pre)),
	μ_fx1d_pre + √(diag(Σ_fx1d_pre)),
	color = "k", alpha = 0.15, label="pointwise std",
)
for i = 1:4
	sim  = chol(Σ_fx1d_pre, Val{:L}) * randn(length(x1d_pre))
	sim += μ_fx1d_pre
	if i == 1
		plot(x1d_pre, sim, "b", alpha = .25, label="cond simulations")
	else
		plot(x1d_pre, sim, "b", alpha = .25)
	end
end
axis("tight")
legend(loc = "best")
=#











#=###############################

 Two dimensional simulation

=###############################

n         = 50
x2d_obs   = rand(n,2)
Σ         = Float64[cov(vec(x2d_obs[i,:]), vec(x2d_obs[j,:])) for i in 1:n, j in 1:n]
Σobs      = Σ +  (0.1)^2 * eye(n)
chlΣobs   = chol(Σobs, Val{:L})
fx2d_obs  = chlΣobs * randn(n)
#=
scatter(x2d_obs[:,1], x2d_obs[:,2], c=fx2d_obs, s = 50, vmin = minimum(fx2d_obs), vmax = maximum(fx2d_obs))
colorbar()
=#




# --- now compute the conditinal expected value, conditional variance and conditional simulations on x1d_pre
function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T})
    m, n = length(vy), length(vx)
    vx = reshape(vx, 1, n)
    vy = reshape(vy, m, 1)
    (repmat(vx, m, 1), repmat(vy, 1, n))
end
meshgrid(v)  = meshgrid(v,v)

mesh_side    = 100
xmesh, ymesh = meshgrid(linspace(-.1, 1.1, mesh_side))

# To construct Σcross and Σpre we put it in a function so it can be jit compiled
function ΣcrossΣpre(xmesh, ymesh, x2d_obs)
	n = size(x2d_obs, 1)
	m = length(xmesh)
	Σcross = Array(Float64, m, n)
	Σpre   = Array(Float64, m, m)
	@inbounds for col in 1:n, row in 1:m
		Σcross[row, col] = cov([xmesh[row], ymesh[row]], vec(x2d_obs[col,:]))
	end
	@inbounds for col in 1:m, row in 1:m
		Σpre[row, col] = cov([xmesh[row], ymesh[row]], [xmesh[col], ymesh[col]])
	end
	return Σcross, Σpre
end

# check to make sure we have type stability in the local variables (so it can be jitted)
@code_warntype ΣcrossΣpre(xmesh, ymesh, x2d_obs)

@time Σcross, Σpre = ΣcrossΣpre(xmesh, ymesh, x2d_obs)

μ_fx2d_pre =  Σcross * (Σobs \ fx2d_obs)
Σ_fx2d_pre =  Σpre -  Σcross * (Σobs \ transpose(Σcross))


#= plot the data and the conditional mean
pcolor(xmesh, ymesh, reshape(μ_fx2d_pre, mesh_side, mesh_side), vmin = minimum(μ_fx2d_pre), vmax = maximum(μ_fx2d_pre))
scatter(x2d_obs[:,1], x2d_obs[:,2], c=fx2d_obs, s = 50, vmin = minimum(μ_fx2d_pre), vmax = maximum(μ_fx2d_pre))
colorbar()
axis("tight")
=#



#= plot the a conditinal simulation
cholSim = chol(Σ_fx2d_pre, Val{:L})
sim = μ_fx2d_pre + cholSim * randn(length(μ_fx2d_pre))
pcolor(xmesh, ymesh, reshape(sim, mesh_side, mesh_side), vmin = minimum(fx2d_obs), vmax = maximum(fx2d_obs))
scatter(x2d_obs[:,1], x2d_obs[:,2], c=fx2d_obs, s = 50, vmin = minimum(fx2d_obs), vmax = maximum(fx2d_obs))
colorbar()
axis("tight")
=#









#=###############################

 Save data and obs locations

=###############################

h5write("data_set1.h5", "x1d_obs", x1d_obs)
h5write("data_set2.h5", "x2d_obs", x2d_obs)
h5write("data_set1.h5", "fx1d_obs", fx1d_obs)
h5write("data_set2.h5", "fx2d_obs", fx2d_obs)


#= load
x1d_obs    = h5read("data_set1.h5", "x1d_obs")
x2d_obs    = h5read("data_set2.h5", "x2d_obs")
fx1d_obs   = h5read("data_set1.h5", "fx1d_obs")
fx2d_obs   = h5read("data_set2.h5", "fx2d_obs")
=#
