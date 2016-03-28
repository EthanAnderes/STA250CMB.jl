module STA250CMB

export	FFTgrid

FFTW.set_num_threads(CPU_CORES)


##########################################################
#=
Definition of the FFTgrid Type.
Holds grid, model and planned FFT parameters for the quadratic estimate.
Allows easy argument passing.
=#
#############################################################

immutable FFTgrid{dm, T}
	# grid parameters
	period::Float64
	nside::Int64
	deltx::Float64
	deltk::Float64
	nyq::Float64
	x::Array{Array{Float64,dm},1}
	k::Array{Array{Float64,dm},1}
	r::Array{Float64,dm}
	# saved plans for fast fft
	FFT::T
end

"""
`FFTgrid(dm, period, nside)` constructor for FFTgrid{dm,T} type
"""
function FFTgrid(dm, period, nside)
	dm_nsides = fill(nside,dm)   # [nside,...,nside] <- dm times
	deltx     = period / nside
	deltk     = 2π / period
	nyq       = 2π / (2deltx)
	x         = [fill(NaN, dm_nsides...) for i = 1:dm]
	k         = [fill(NaN, dm_nsides...) for i = 1:dm]
	r         = fill(NaN, dm_nsides...)
	tmp       = rand(Complex{Float64},dm_nsides...)
	unnormalized_FFT = plan_fft(tmp; flags = FFTW.PATIENT, timelimit = 5)
	# unnormalized_FFT = plan_fft(rand(Complex{Float64},dm_nsides...); flags = FFTW.ESTIMATE, timelimit = 10)
	# unnormalized_FFT = plan_fft(rand(Complex{Float64},dm_nsides...); flags = FFTW.MEASURE, timelimit = 20)
	FFT = complex( (deltx / √(2π))^dm ) * unnormalized_FFT
	FFT \ tmp  # <---- activate fast ifft
	g = FFTgrid{dm, typeof(FFT)}(period, nside, deltx, deltk, nyq, x, k, r, FFT)
	g.x[:], g.k[:] = getgrid(g)
	g.r[:]  =  √(sum([abs2(kdim) for kdim in g.k]))
	return g
end
function getxkside{dm,T}(g::FFTgrid{dm,T})
	deltx    = g.period / g.nside
	deltk    = 2π / g.period
	xco_side = zeros(g.nside)
	kco_side = zeros(g.nside)
	for j in 0:(g.nside-1)
		xco_side[j+1] = (j < g.nside/2) ? (j*deltx) : (j*deltx - g.period)
		kco_side[j+1] = (j < g.nside/2) ? (j*deltk) : (j*deltk - 2*π*g.nside/g.period)
	end
	xco_side, kco_side
end
function getgrid{T}(g::FFTgrid{1,T})
	xco_side, kco_side = getxkside(g)
	xco      = Array{Float64,1}[ xco_side ]
	kco      = Array{Float64,1}[ kco_side ]
	return xco, kco
end
function meshgrid(side_x,side_y)
    	nx = length(side_x)
    	ny = length(side_y)
    	xt = repmat(vec(side_x).', ny, 1)
    	yt = repmat(vec(side_y)  , 1 , nx)
    	return xt, yt
end
function getgrid{T}(g::FFTgrid{2,T})
	xco_side, kco_side = getxkside(g)
	kco1, kco2 = meshgrid(kco_side, kco_side)
	xco1, xco2 = meshgrid(xco_side, xco_side)
	kco    = Array{Float64,2}[kco1, kco2]
	xco    = Array{Float64,2}[xco1, xco2]
	return xco, kco
end



import Base.show
function Base.show{dm, T}(io::IO, parms::FFTgrid{dm, T})
	for vs in fieldnames(parms)
		(vs != :FFT) && (vs != :IFFT) && println(io, "$vs => $(getfield(parms,vs))")
		println("")
	end
end



# -------- converting from pixel noise std to noise per-unit pixel
σunit_to_σpixl(σunit, deltx, dm) = σunit / √(deltx ^ dm)
σpixl_to_σunit(σpixl, deltx, dm) = σpixl * √(deltx ^ dm)
function cNNkgen{dm}(r::Array{Float64,dm}, deltx; σunit=0.0, beamFWHM=0.0)
	beamSQ = exp(- (beamFWHM ^ 2) * (abs2(r) .^ 2) ./ (8 * log(2)) )
	return ones(size(r)) .* σunit .^ 2 ./ beamSQ
end


# -------- Simulate a mean zero Gaussian random field in the pixel domain given a spectral density.
function grf_sim_xk{dm, T}(cXXk::Array{Float64,dm}, p::FFTgrid{dm, T})
	nsz = size(cXXk)
	dx  = p.deltx ^ dm
	zzk = √(cXXk) .* (p.FFT * randn(nsz) ./ √(dx))
	return real(p.FFT \ zzk), zzk
end




##########################################################
#=
Miscellaneous functions
=#
#############################################################
function radial_power{dm,T}(fk, smooth::Number, g::FFTgrid{dm,T})
	rtnk = Float64[]
	dk = g.deltk
	kbins = collect((smooth*dk):(smooth*dk):(g.nyq))
	for wavenumber in kbins
		indx = (wavenumber-smooth*dk) .< g.r .<= (wavenumber+smooth*dk)
		push!(rtnk, sum(abs2(fk[indx]).* (dk.^dm)) / sum(indx))
	end
	return kbins, rtnk
end



squash{T<:Number}(x::T)         = isnan(x) ? zero(T) : isfinite(x) ? x : zero(T)
squash{T<:AbstractArray}(x::T)  = map(squash, x)::T
squash!{T<:AbstractArray}(x::T) = map!(squash, x)::T

end # module
