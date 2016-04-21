# Get the Planck sky maps and healpix software

links  =
[
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/LFI_SkyMap_030_1024_R2.01_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/LFI_SkyMap_044_1024_R2.01_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/LFI_SkyMap_070_1024_R2.01_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/LFI_SkyMap_070_2048_R2.01_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_100_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_143_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_217_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_353_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_545_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/HFI_SkyMap_857_2048_R2.02_full.fits",
"http://irsa.ipac.caltech.edu/data/Planck/release_2/all-sky-maps/maps/component-maps/cmb/COM_CMB_IQU-commander-field-Int_2048_R2.01_full.fits"
]

map_names  =
[
"LFI_SkyMap_030_1024_R2.01_full.fits",
"LFI_SkyMap_044_1024_R2.01_full.fits",
"LFI_SkyMap_070_1024_R2.01_full.fits",
"LFI_SkyMap_070_2048_R2.01_full.fits",
"HFI_SkyMap_100_2048_R2.02_full.fits",
"HFI_SkyMap_143_2048_R2.02_full.fits",
"HFI_SkyMap_217_2048_R2.02_full.fits",
"HFI_SkyMap_353_2048_R2.02_full.fits",
"HFI_SkyMap_545_2048_R2.02_full.fits",
"HFI_SkyMap_857_2048_R2.02_full.fits",
"COM_CMB_IQU-commander-field-Int_2048_R2.01_full.fits"
]

save_path = "/Users/ethananderes/Dropbox/Courses/STA250CMB/data/planck_skymaps"

# download(links[5], "$save_path/$(map_names[5])")



#=  Healpix Installation
Documentation at http://healpy.readthedocs.org/en/latest/

To install you can do
```
pip install --user healpy
```
=#


using PyCall, PyPlot
@pyimport healpy as hp
planck_map = hp.read_map("$save_path/$(map_names[5])", field = 0, memmap = true)
hp.mollview(planck_map, xsize = 800, title = "temperature", min = -0.00051, max = 0.00051)
