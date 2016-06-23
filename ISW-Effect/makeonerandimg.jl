i_start = 3
i_end   = 3

include("lib.jl")
name = "CoordRand100"

using PyCall
@pyimport healpy as hp
@pyimport healpy.fitsfunc as fitsfunc;
@pyimport healpy.pixelfunc as pixelfunc;
@pyimport numpy as np;

println("---| Reading a polarization map at 100 GHz")
path = "/home/inchani/STA250/";

#targetimg = "randimg"
targetimg = "randimg_highres"

map_name = "HFI_SkyMap_100_2048_R2.02_full.fits";              # Polarization map at 100 GHz
ext = "_HFI"
map_name = "COM_CMB_IQU-smica-field-Int_2048_R2.01_full.fits"; # SMICA CMB map
ext = "_SMICA"



dθ = dϕ = 0.0007669903939429012;  # 5 arcmin of resolution to radian
NSIDE = 2048;
Nested = false;
I_STOKES = hp.read_map("$path$map_name", field = 0, memmap = true);
dim = length(I_STOKES);

const dtheta_deg = 15.
const dtheta = dtheta_deg / 180 * pi;   # 15 degrees in radian
const FWHM    = 30. / 60. * pi / 180;   # 30. arcmin to radian unit (See Planck 2013 ISW paper)
const σ       = FWHM / 2.355            # 2.355 ~ 2√(2log(2))
const σnorm2  = 2.*σ^2.
const σlim2   = (3σ)^2.  

const angsize    = copy(dtheta_deg*2)             # width and height in degree 
const XYsize     = angsize * pi / 180;            # in radian 
#const res        = 6. / 60. * pi / 180;      # 6 arcmin of pixel size in radian unit (See Planck 2013 ISW paper)
const res        = 3. / 60. * pi / 180;      # 3 arcmin of pixel size in radian unit (See Planck 2013 ISW paper)
const Nsize      = Int64(round(XYsize/res)); # 600

const Tmin = -593.5015506111085; # mu K  
const Tmax =  709.0113358572125; # mu K 
# min and max temperature if we take out 40 % of sky as foreground



#In a galactic mask map, I ruled out " mask value = 0" pixels in 70% coverage case
println("---| Reading mask maps")
GalMapFile = "HFI_Mask_GalPlane-apo5_2048_R2.00.fits"
PtMapFile  = "HFI_Mask_PointSrc_2048_R2.00.fits"
GalMap     = hp.read_map("$path$GalMapFile", field = 3, memmap = true); # 70% sky coverage 
PtMap      = hp.read_map("$path$PtMapFile", field = 0, memmap = true);  



println("---| Constructing a Gaussian kernel of $Nsize by $Nsize map")

x1d      = linspace(-XYsize*0.5,XYsize*0.5,Nsize)
y1d      = linspace(XYsize*0.5,-XYsize*0.5,Nsize)
Tmap     = Float64[ GKernel(xi,yi,0.,0.) for xi in x1d, yi in y1d];
Umap     = Float64[ GKernel(xi,yi,0.,0.) > 0.? 1.: 0. for xi in x1d, yi in y1d];
TmapNorm = sum(Tmap);
Tmap    /= TmapNorm;


println("---| masking only point sources")
const planck_map = copy(I_STOKES) * 1e6 # Converting it to mu K scale;

for i = 1:length(PtMap)
    if PtMap[i] == 0.
        planck_map[i] = hp.UNSEEN
    end
end




println("---| Let\'s start stacking random images")

#####################################
CoordSCluster = np.load("$path$name"".npy")
#####################################


i = 0; Nsample = i_end - i_start + 1
while (i < Nsample)
    n = i+i_start
    θc0, ϕc0 = CoordSCluster[n,:]
    θ = θc0 * 180 / pi
    ϕ = ϕc0 * 180 / pi

    println("   |>> No. $n with angular position, (θ,ϕ) = ($θ, $ϕ)")  
    @time Npix, ind = SpheCoord2Index2(θc0-dtheta, θc0+dtheta, ϕc0-dtheta, ϕc0+dtheta)      
    println("   |>> total Number of pixels = $Npix")

    println("---| Start constructing an image")

    @time MakeIndivImg(θc0, ϕc0, n, ind);
    i +=1
end
