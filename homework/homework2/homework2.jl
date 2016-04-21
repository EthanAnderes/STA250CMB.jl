#=
# Homework 2 (Due Monday, May 2)

The goal of this exercise is to impiment the Metropolis-Hastings algorithm and the
Affine-invariant ensemble MCMC for sampling from the basic 6-parameter LCDM model under idealized data.

First download the simulated bandpowers with the following command
=#

download("https://github.com/EthanAnderes/STA250CMB.jl/homework/homework2/bandpowers.h5")

# Now load them into Julia with the command

using HDF5
bandpowers = h5read("bandpowers.h5", "bandpowers")

#=
These bandpowers were simulated from the Julia lecture `STA250CMB/lectures/julia_lecture5_LCDM_MCMC/julia_lecture5.ipynb`.
You can see that lecture for more details of the simulation procedure but basically
the bandpowers are given by
\[
\sigma_{\ell} = \frac{1}{2\ell + 1}\sum_{m=-\ell}^\ell |d_{\ell m}|^2.
\]
The data spherical harmonics are simulated from the idealized data model
\[
d_{\ell m} = T_{\ell m} + \epsilon_{\ell m}
\]
where the spectral density of $\epsilon_{\ell m}$ is given by $\sigma^2 \exp\left(\frac{b^2}{8\log 2}\ell(\ell+1)\right)$ with
noise and beam given by
\[
\sigma = \frac{10.0}{3437.75}
b      = 0.0035.
\]
Note: the beam full width at half max is approximately 12 arcmins wide.

To complete the homework I would like you to impliment Metropolis-Hastings and Affine-invariant ensemble MCMC
for sampling from the posterior on LCDM parameters given these simulated bandpowers. Use a unform prior
for the LCDM parameters. You can choose whichever proposal distribution you like, so long as the resulting chain works
mixes well. For both Markov chains, plot the iterations of the samples, the autocorrelation of the chain (after a sufficient
burn-in) and make a triangle pairwise-density plot comparing the posterior contours of your chain to the WMAP chain (see STA250CMB/lectures/julia_lecture5_LCDM_MCMC/julia_lecture5.ipynb)
for details on downloading the WMAP chain and using `getDist` for plotting.
=#
