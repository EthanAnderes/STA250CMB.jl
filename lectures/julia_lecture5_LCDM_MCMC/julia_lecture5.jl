# some source code templated before moving to IJulia notebook.

link      = "http://lambda.gsfc.nasa.gov/data/map/dr5/dcp/chains/wmap_lcdm_wmap9_chains_v5.tar.gz"
# download(link, "wmap_lcdm_wmap9_chains_v5.tar.gz")
# run(`gunzip wmap_lcdm_wmap9_chains_v5.tar.gz`)

wmap_path = "/Users/ethananderes/Dropbox/Courses/STA250CMB/data/wmap_chain"
# run(`tar -xf wmap_lcdm_wmap9_chains_v5.tar --directory $wmap_path`)
# run(`rm wmap_lcdm_wmap9_chains_v5.tar`)
# run(`head $wmap_path/omegach2`)
nlines = countlines("$wmap_path/omegach2")

# It appears this doesn't work since there are both a column of integers and floats
# omega_b_chain = Mmap.mmap("$wmap_path/omegabh2", Array{Float64, 2}, (nlines,2))

nchain = 100_000
omega_b_chain     = readdlm("$wmap_path/omegabh2")[1:nchain,2]
omega_cdm_chain   = readdlm("$wmap_path/omegach2")[1:nchain,2]
tau_reio_chain    = readdlm("$wmap_path/tau")[1:nchain,2]
theta_s_chain     = readdlm("$wmap_path/thetastar")[1:nchain,2]
A_s_109_chain     = readdlm("$wmap_path/a002")[1:nchain,2]  # <-- 10⁹ * A_s
n_s_chain         = readdlm("$wmap_path/ns002")[1:nchain,2]
# note: kstar here is 0.002

full_chain    = hcat(omega_b_chain, omega_cdm_chain, tau_reio_chain, theta_s_chain, A_s_109_chain, n_s_chain)
names_chain   = [:omega_b, :omega_cdm, :tau_reio, :theta_s, :A_s_109, :n_s]
Σwmap         = cov(full_chain)
wmap_best_fit = vec(mean(full_chain,1))

subplot(3,1,1)
plot(omega_b_chain[1:100:end], label = "omega_b_chain")
xlabel("iteration")
legend()
subplot(3,1,2)
plot(theta_s_chain[1:100:end], label = "theta_s_chain")
xlabel("iteration")
legend()
subplot(3,1,3)
plot(n_s_chain[1:100:end], label = "n_s_chain")
xlabel("iteration")
legend()

#= ###############################

The loglikelihood

=# ##############################

using PyCall

@pyimport pypico
picodata_path = "/Users/ethananderes/Dropbox/Courses/STA250CMB/data/pypico/pico3_tailmonty_v34.dat"
const picoload = pypico.load_pico(picodata_path)

# --------  wrap pico
function pico(x)
    omega_b     = x[1]
    omega_cdm   = x[2]
    tau_reio    = x[3]
    theta_s     = x[4]
    A_s_109     = x[5]
    n_s         = x[6]
    plout::Dict{ASCIIString, Array{Float64,1}} = picoload[:get](;
        :re_optical_depth => tau_reio,
        symbol("scalar_amp(1)") =>  1e-9*A_s_109,
        :theta => theta_s,
        :ombh2 => omega_b,
        :omch2 => omega_cdm,
        symbol("scalar_spectral_index(1)") => n_s,
        :massive_neutrinos => 3.04,
        :helium_fraction => 0.25,
        :omnuh2 => 0.0,
        symbol("scalar_nrun(1)") => 0.0,
        :force     => true
    )
    clTT::Array{Float64,1} = plout["cl_TT"]
    ells   = 0:length(clTT)-1
    clTT .*= 2π ./ ells ./ (ells + 1)
    clTT[1] = 0.0
    return clTT
end



function loglike(x, bandpowers, σ², b²)
    ell = 0:length(bandpowers)-1
    cldd = pico(x) + σ² * exp(b² .* ell .* (ell + 1) ./ (8log(2)))
    rtn = 0.0
    @inbounds for l in ell[2:end]
      rtn -= log(cldd[l+1]) * (2l+1) / 2
      rtn -= (bandpowers[l+1] / cldd[l+1]) * (2l+1) / 2
    end
    return rtn
end




#= ###############################

Generate some fake data

=# ##############################

using PyPlot, HDF5

#beam and spectral density are set to approximately match WMAP
σ² = (10.0/3437.75)^2    #<---10μkarcmin noise level converted to per radian pixel (1 radian = 3437.75 arcmin)
b² = (0.0035)^2 #<-- pixel width 0.2ᵒ ≈ 12.0 armin ≈ 0.0035 radians

lcdm_sim_truth = full_chain[rand(1:nchain),:]
h5write("lectures/julia_lecture5_LCDM_MCMC/lcdm_sim_truth.h5", "lcdm_sim_truth", lcdm_sim_truth)

clTT = pico(lcdm_sim_truth)
ell  = 0:length(clTT)-1
cldd = clTT + σ² * exp(b² .* ell .* (ell + 1) ./ (8log(2)))


bandpowers = Array(Float64, length(cldd))
for l in ell
  bandpowers[l+1] = abs2( √(cldd[l+1]) * randn() )
  for m in 1:l
    bandpowers[l+1] += 2abs2( √(cldd[l+1]/2) * randn() )
    bandpowers[l+1] += 2abs2( √(cldd[l+1]/2) * randn() )
  end
  bandpowers[l+1] ./= (2l + 1)
end
h5write("homework/homework2/bandpowers.h5", "bandpowers", bandpowers)


semilogy(ell[1:2000], bandpowers[1:2000], label="bandpowers")
semilogy(ell[1:2000], clTT[1:2000], label="temp spectrum")
semilogy(ell[1:2000], cldd[1:2000], label="data spectrum")
semilogy(ell[1:2000], (cldd-clTT)[1:2000], label="noise spectrum")
legend()



#= ###########################

NLopt

=# #############################

using NLopt

# here are some optimization algorithms that do not require gradient calculations
# see http://ab-initio.mit.edu/wiki/index.php/NLopt_Reference for a reference
algm = [:LN_BOBYQA, :LN_COBYLA, :LN_PRAXIS, :LN_NELDERMEAD, :LN_SBPLX]

llmin(x, grad)  = loglike(x, bandpowers, σ², b²)

#dx   = eig(Σwmap) |> x -> 0.01*x[2]*√(x[1]) # <--- start direction
opt = Opt(algm[1], 6)
#initial_step!(opt, dx)
upper_bounds!(opt, [0.034, 0.2,  0.55,  .0108, exp(4.0)/10,  1.25])
lower_bounds!(opt, [0.018, 0.06, 0.01,  .0102, exp(2.75)/10, 0.85])  # <-- pico training bounds
maxtime!(opt, 5*60.0)   # <--- max time in seconds
max_objective!(opt, llmin)
optf, optx, ret = optimize(opt, wmap_best_fit)

# compare the fits
hcat(optx, lcdm_sim_truth, wmap_best_fit)

#= =========================
note: Here are bounding box constraints used for training pypico.
      They are the upper and lower bounds used in NLopt.

    0.018<      omega_b     < 0.034
    0.06 <      omega_cdm   < 0.2
		0.01 <      tau_reio    < 0.55
    .0102 <     theta_s     < .0108
exp(2.75)/10 <  A_s_109     < exp(4.0)/10
		0.85 <      n_s         < 1.25
=######################################




#= ###########################

getDist

https://pypi.python.org/pypi/GetDist/
http://getdist.readthedocs.org/en/latest/index.html

Installation `sudo pip install getdist`

=# #############################

using PyCall, PyPlot

@pyimport getdist
@pyimport getdist.plots as plots
samples = getdist.MCSamples(samples=full_chain, names=names_chain)
g = plots.getSubplotPlotter()
g[:triangle_plot](samples, filled=true)
# g[:export]("output_file.pdf")
