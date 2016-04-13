using Stat250CMB
using Base.Test

# write your own tests here
@test 1 == 1



#=###########################################

Do a quick test that of the Fourier transform and derivatives

=##########################################################
#
#
# σ = 0.2 * g.period
# φx = exp(-0.5 * (g.x[1].^2 + g.x[2].^2) ./ (σ^2)) ./ (2π) ./ (σ^2)
# φk = exp(-0.5 * (g.k[1].^2 + g.k[2].^2) .* (σ^2)) ./ (2π)
#
# figure()
# subplot(2,2,1)
# imshow(φx);colorbar()
# subplot(2,2,2)
# imshow(real(g.FFT \ φk));colorbar()
# subplot(2,2,3)
# imshow(φk);colorbar()
# subplot(2,2,4)
# imshow(real(g.FFT * φx));colorbar()
#
#
#
# σ = 0.2 * g.period
# φx = (-g.x[2]./(σ^2)) .* exp(-0.5 * (g.x[1].^2 + g.x[2].^2) ./ (σ^2)) ./ (2π) ./ (σ^2)
# φk = (g.k[2].*im)     .* exp(-0.5 * (g.k[1].^2 + g.k[2].^2) .* (σ^2)) ./ (2π)
#
# figure()
# subplot(2,2,1)
# imshow(φx);colorbar()
# subplot(2,2,2)
# imshow(real(g.FFT \ φk));colorbar()
# subplot(2,2,3)
# imshow(imag(φk));colorbar()
# subplot(2,2,4)
# imshow(imag(g.FFT * φx));colorbar()
#
#
# g.x[1][1:5,1:5]
# g.x[2][1:5,1:5]
# ex[1:5,1:5]
# real(g.FFT \ (im .* g.k[1] .* ek))[1:5,1:5]
# real(g.FFT \ (im .* g.k[2] .* ek))[1:5,1:5]
#
#
# figure()
# subplot(2,2,1)
# imshow(diff(ex,1)./diff(g.x[2],1))
# subplot(2,2,2)
# imshow(real(g.FFT \ (im .* g.k[2] .* ek)))
# subplot(2,2,3)
# imshow(diff(ex,2)./diff(g.x[1],2))
# subplot(2,2,4)
# imshow(real(g.FFT \ (im .* g.k[1] .* ek)))
