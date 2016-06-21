
# Function to return pixel indices using coordinates of superclusters
function SpheCoord2Index(θmin::Float64,θmax::Float64,ϕmin::Float64,ϕmax::Float64; discrepancy = 0.7)
    #θmax > 1pi ? θmax = pi : θmax = θmax
    #θmin < 0.  ? θmin = 0. : θmin = θmin
    
    index = Array(Int64,0)
    
    #if (θmax > 160pi / 180) | (θmin < 10pi / 180) 
    #    println("   |> Too high or low latitude... exit")
    #    return 0, index
    #end

    if θmax > 1*pi
        println("   |> θmax is greater than 179° ... set θmax = 179°")
        θmax = 179. * pi / 180.
    end
    if θmin < 0
        println("   |> θmin is smaller than 1° ... set θmin = 1°")
        θmin = pi / 180.
    end

    θ = copy(θmax)
    Nθpix = 0; Nϕpix = 0; Ntot = 0
    
    # Resolution of CMB map is different from different lattitude... So I will take the bigger one.
    Nϕpix1 = pixelfunc.ang2pix(NSIDE,θmax,ϕmax) - pixelfunc.ang2pix(NSIDE,θmax,ϕmin)  
    Nϕpix2 = pixelfunc.ang2pix(NSIDE,θmin,ϕmax) - pixelfunc.ang2pix(NSIDE,θmin,ϕmin)  


    i   = pixelfunc.get_all_neighbours(NSIDE,θmax,ϕmax)[6]
    i2  = pixelfunc.get_all_neighbours(NSIDE,θmin,ϕmax)[6]
    l,b = pixelfunc.pix2ang(NSIDE,i)
    l,b2= pixelfunc.pix2ang(NSIDE,i2)
    dϕ  = min(abs(b - ϕmax), abs(b2 - ϕmax))
   
    Nϕ  = (ϕmax - ϕmin) / dϕ
    
    #println("   |> $θmin, $θmax, $ϕmin, $ϕmax, Nϕ = $Nϕ")
    println("   |> dϕ = $dϕ,  Nϕ = $Nϕ")
    if Nϕ < 1.
        println("   |> Poor resolution... exit")
        return 0, index
    end
    
    
    if (Nϕpix1 > 0) & (Nϕpix2 > 0)
        Nϕpix = max(Nϕpix1,Nϕpix2)
    else
        Nϕpix = -1
    end

    println("   |> finding pixels in the region...")
    
    if ((ϕmax > 2pi) | (ϕmin * ϕmax < 0)) 
        Nϕpix = pixelfunc.ang2pix(NSIDE,θmax,ϕmax) - pixelfunc.ang2pix(NSIDE,θmax,ϕmin)        
        N = 1; ϕ = ϕmax;    
        while (ϕ > 0.)
            i1 = pixelfunc.ang2pix(NSIDE,θmax,ϕ)
            i2 = pixelfunc.get_all_neighbours(NSIDE,θmax,ϕ)[2]
            N += 1
            l, ϕ = pixelfunc.pix2ang(NSIDE,i2)       
            if ϕ > ϕmax
                ϕ -= 2pi
            end
        end           
        N2 = copy(N-1)       
        N = 1; ϕ = 0.;
        
        while (ϕ > ϕmin)
            i1 = pixelfunc.ang2pix(NSIDE,θmax,ϕ)
            i2 = pixelfunc.get_all_neighbours(NSIDE,θmax,ϕ)[2]
            N += 1
            l, ϕ = pixelfunc.pix2ang(NSIDE,i2)
            if ϕ > 0.
                ϕ -= 2pi
            end
        end
        N1 = copy(N-1) 
        while θ >= θmin
            ϕ = ϕmin;
            ist1 = pixelfunc.ang2pix(NSIDE,θ,ϕ)
            ist2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[3] # Again Pixels on North West to fully cover area.
            ind1 = Int64[i for i=ist1+1:ist1+N1]            
            ind2 = Int64[i for i=ist2+1:ist2+N1]

            index = vcat(index,ind1,ind2)                    
            ϕ = ϕmax;
            ist1 = pixelfunc.ang2pix(NSIDE,θ,ϕ)
            ist2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[3] # Again Pixels on North West to fully cover area.
            ind1 = Int64[i for i=ist1-N2:ist1-1]            
            ind2 = Int64[i for i=ist2-N2:ist2-1]            
            
            index = vcat(index,ind1,ind2)        
            i = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[4]
            θ, b = pixelfunc.pix2ang(NSIDE,i) 
            Nθpix += 2
        end
        Nϕpix = N1 + N2
        if abs( (Nϕpix-Nϕ)/Nϕ ) > discrepancy
            println("   |> Found a huge discrepancy btwn Nϕpix($Nϕpix) and Nϕ... exit")
            return 0, index
        end
        println("   |> Scheme No.1 & returning ($N1+$N2=$Nϕpix, $Nθpix) array")
        return length(index), index
    end
    
    if Nϕpix < 0        
        N = 1; dind = 1;
        ϕ = ϕmin
        while (dind == 1) & (ϕ < ϕmax)
            i1 = pixelfunc.ang2pix(NSIDE,θmax,ϕ)
            i2 = pixelfunc.get_all_neighbours(NSIDE,θmax,ϕ)[6]
            dind = i2 - i1
            if dind > 0
                N += 1
            end
            l, ϕ = pixelfunc.pix2ang(NSIDE,i2)
        end           
        N1 = copy(N)
        #println("ϕ starting at $ϕ")
        N = 1; dind = 1;
        while (dind == 1) & (ϕ < ϕmax)
            i1 = pixelfunc.ang2pix(NSIDE,θmax,ϕ)
            i2 = pixelfunc.get_all_neighbours(NSIDE,θmax,ϕ)[2]
            dind = i1 - i2
            if dind > 0
                N += 1
            end
            l, ϕ = pixelfunc.pix2ang(NSIDE,i2)
        end
        #println("ϕ ending at $ϕ")        
        N2 = copy(N)
        while θ >= θmin
            ϕ = ϕmin;
            ist1 = pixelfunc.ang2pix(NSIDE,θ,ϕ)
            ist2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[3] # Again Pixels on North West to fully cover area.
            ind1 = Int64[i for i=ist1+1:ist1+N1]            
            ind2 = Int64[i for i=ist2+1:ist2+N1]

            index = vcat(index,ind1,ind2)        
            #(SW, W, NW, N, NE, E, SE and S )
            
            ϕ = ϕmax;
            ist1 = pixelfunc.ang2pix(NSIDE,θ,ϕ)
            ist2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[3] # Again Pixels on North West to fully cover area.
            ind1 = Int64[i for i=ist1-N2:ist1-1]            
            ind2 = Int64[i for i=ist2-N2:ist2-1]            
            
            index = vcat(index,ind1,ind2)        
            i = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[4]
            θ, b = pixelfunc.pix2ang(NSIDE,i) 
            Nθpix += 2
        end
        Nϕpix = N1 + N2
        if abs( (Nϕpix-Nϕ)/Nϕ ) > discrepancy
            println("   |> Found a huge discrepancy btwn Nϕpix($Nϕpix) and Nϕ... exit")
            return 0, index
        end        
        println("   |> Scheme No.2 & returning ($N1+$N2=$Nϕpix, $Nθpix) array")        
        return length(index), index

    end    
     

    if abs( (Nϕpix-Nϕ)/Nϕ ) > discrepancy
        println("   |> Found a huge discrepancy btwn Nϕpix($Nϕpix) and Nϕ... exit")
        return 0, index
    end
     
    while θ > θmin
        ϕ = ϕmin;
        ist1 = pixelfunc.ang2pix(NSIDE,θ,ϕ)
        ist2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[3] # Again Pixels on North West to fully cover area.
        ind1 = Int64[i for i=ist1:ist1+Nϕpix-1]            
        ind2 = Int64[i for i=ist2:ist2+Nϕpix-1]
        
        index = vcat(index,ind1,ind2)        
        #(SW, W, NW, N, NE, E, SE and S )
        i = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ)[4]
        θ, b = pixelfunc.pix2ang(NSIDE,i) 
        Nθpix += 2
    end
    println("   |> Scheme No.3 & returning ($Nϕpix, $Nθpix) array")        

    return length(index), index
end





# Function to Shift an Array for superposition
function ShiftArray(X::Array{Float64,2},drow::Int64,dcol::Int64)
    Nrow  = Int(size(X)[1] / 2)
    Ncol  = Int(size(X)[2] / 2)
    rtn   = zeros(size(X)[1], size(X)[2]) 
    
    if (drow >= 0) & (dcol >= 0)
        rtn[1+drow:2Nrow,1+dcol:2Ncol] = X[1:2Nrow-drow,1:2Ncol-dcol]
        return rtn
    end
    
    if (drow <= 0) & (dcol <= 0)
        rtn[1:2Nrow+drow,1:2Ncol+dcol] = X[1-drow:2Nrow,1-dcol:2Ncol] 
        return rtn
    end
    
    if (drow >= 0) & (dcol < 0)
        rtn[1+drow:2Nrow,1:2Ncol+dcol] = X[1:2Nrow-drow,1-dcol:2Ncol] 
        return rtn
    end
    
    if (drow < 0) & (dcol >= 0)
        rtn[1:2Nrow+drow,1+dcol:2Ncol] = X[1-drow:2Nrow,1:2Ncol-dcol] 
        return rtn
    end     
end

# Function for picking up a degraded indice 
# in case that the number of pixels is too many
function pick_random_ind(index::Array{Int64,1},num::Int64)
    
    Ntot = length(index)       
    if (num == 0) | (num > Ntot)
        return index
    end

    j = 1
    ind = Array(Int64, 0)
    i = Int64( round(rand() * (Ntot-1)+1) )
    ind = vcat(ind,i)
    while j < num
        i = Int64( floor(1+ rand()*(Ntot-1)) )
        cnt = countnz(ind-i)
        #println(ind,ind-i,i)
        if cnt == j
            ind = vcat(ind,i)
            j   += 1
        end
    end

    return index[ind]
end

function GKernel(x::Float64,y::Float64,x₀::Float64,y₀::Float64)
    r2 = (x-x₀)^2. + (y-y₀)^2.
    if r2 < σlim2
        return exp( -r2 / σnorm2 )
    else
        return 0.
    end
end


# Function for Stacking images
function StackImg(i0::Int64,i1::Int64; degrade=1)
    StackImage = zeros(Nsize, Nsize);   # [row, col]
    if degrade == 1
        println("degrading image is on")
    end
    println("   |> starting from $i0.")
    for i = i0:i1     # index of superclusters
        θc, ϕc = CoordSCluster[id_sc[i],:]   # Center Coord. of Supercluster
        i == 1 ? ist = 1: ist = 1 + sum(N_sc[1:i-1]) 
        percent = 20
        
        if (degrade == 1) & (Nsize*Nsize < N_sc[i])
            from = N_sc[i]
            to   = Nsize*Nsize
            println("   |> degrading img: $from to $to pixels")
            i_sc_pixel_new = pick_random_ind(i_sc_pixel[ist:ist+N_sc[i]]-1,to)
            println("   |> degrading img: done")
            for j = 1:to
                if planck_map[i_sc_pixel_new[j]] > Tmin 
                    θ, ϕ = pixelfunc.pix2ang(NSIDE,i_sc_pixel_new[j])
                    if ϕ > ϕc + dtheta
                        ϕ -= 2pi
                    end
                    if ϕ < ϕc - dtheta
                        ϕ += 2pi
                    end
                    row_shift = Int64(round( (θ - θc) /res )) 
                    col_shift = Int64(round( (ϕ - ϕc) /res )) 
                    StackImage += ShiftArray(Tmap,row_shift, col_shift) * planck_map[i_sc_pixel_new[j]]               
                end
            end
            
            
        else
            N = N_sc[i]
            println("   |> No. $i with $N elements") 
            TStackOne = zeros(Nsize, Nsize);
            UStackOne = zeros(Nsize, Nsize);
            for j = ist:ist+N_sc[i]-1    # pixel index of a supercluster
                if planck_map[i_sc_pixel[j]] > Tmin # exlude the masked regions
                    θ, ϕ = pixelfunc.pix2ang(NSIDE,i_sc_pixel[j])
                    if ϕ > ϕc + dtheta
                        ϕ -= 2pi
                    end
                    if ϕ < ϕc - dtheta
                        ϕ += 2pi
                    end
                    row_shift = Int64(round( (θ - θc) /res )) 
                    col_shift = Int64(round( (ϕ - ϕc) /res )) 
                    TStackOne += ShiftArray(Tmap,row_shift, col_shift) * planck_map[i_sc_pixel[j]]
                    UStackOne += ShiftArray(Umap,row_shift, col_shift)
                    #if Int64(round(100. * (j - ist) / N_sc[i])) > percent
                    #    println("   |> $percent % is done.")
                    #    percent += 20
                    #end
                end
            end
            println("   |>> averaging one stacked image")
            for j = 1:length(TStackOne)
                if UStackOne[j] > 0.
                    TStackOne[j] /= UStackOne[j]
                end
            end
            StackImage += TStackOne
        end
        println("   |>> No. $i is done.")
    end
    return StackImage / (i1 - i0 + 1)
end


# Function for Stacking random images
function StackRandImg(CoordRand::Array{Float64, 2})
    Ntry = 1;
    Nrs        = length(CoordRand[:,1])
    N_rs       = Array(Int64, 0)

    StackImage = zeros(Nsize, Nsize)
    println("start stacking random images")
    for i = 1:Nrs
        θc, ϕc = CoordRand[i,:]
        N, ind = SpheCoord2Index(θc-dtheta,θc+dtheta,ϕc-dtheta,ϕc+dtheta)  
        println("   |> No. $i with $N elements")
        TStackOne = zeros(Nsize, Nsize);
        UStackOne = zeros(Nsize, Nsize);        
        for j = 1:N
            if planck_map[ind[j]] > Tmin # exlude the masked regions
                θ, ϕ = pixelfunc.pix2ang(NSIDE,ind[j])
                if ϕ > ϕc + dtheta
                    ϕ -= 2pi
                end
                if ϕ < ϕc - dtheta
                    ϕ += 2pi
                end
                row_shift = Int64(round( (θ - θc) /res )) 
                col_shift = Int64(round( (ϕ - ϕc) /res )) 
                TStackOne += ShiftArray(Tmap,row_shift, col_shift) * planck_map[ind[j]]
                UStackOne += ShiftArray(Umap,row_shift, col_shift)
            end
        end
        println("   |>> averaging one stacked image")
        for j = 1:length(TStackOne)
            if UStackOne[j] > 0.
                TStackOne[j] /= UStackOne[j]
            end
        end
        StackImage += TStackOne        
    end
    return StackImage / Nrs
end

# Function for making indiv random images
function MakeIndivRandImg(ist::Int64,iend::Int64,CoordRand::Array{Float64, 2})
    Ntry = 1;
    Nrs        = length(CoordRand[:,1])
    N_rs       = Array(Int64, 0)

    println("start stacking random images")
    for i = ist:iend
        θc, ϕc = CoordRand[i,:]
        N, ind = SpheCoord2Index(θc-dtheta,θc+dtheta,ϕc-dtheta,ϕc+dtheta)  
        println("   |> No. $i with $N elements")
        TStackOne = zeros(Nsize, Nsize);
        UStackOne = zeros(Nsize, Nsize);        
        for j = 1:N
            if planck_map[ind[j]] > Tmin # exlude the masked regions
                θ, ϕ = pixelfunc.pix2ang(NSIDE,ind[j])
                if ϕ > ϕc + dtheta
                    ϕ -= 2pi
                end
                if ϕ < ϕc - dtheta
                    ϕ += 2pi
                end
                row_shift = Int64(round( (θ - θc) /res )) 
                col_shift = Int64(round( (ϕ - ϕc) /res )) 
                TStackOne += ShiftArray(Tmap,row_shift, col_shift) * planck_map[ind[j]]
                UStackOne += ShiftArray(Umap,row_shift, col_shift)
            end
        end
        println("   |>> averaging one stacked image")
        for j = 1:length(TStackOne)
            if UStackOne[j] > 0.
                TStackOne[j] /= UStackOne[j]
            end
        end
        np.save("$path""randimg_$coordname""_$i$ext",TStackOne)
    end
end



function MakeIndivImg(θc::Float64, ϕc::Float64, i_target::Int64, pixelIDs::Array{Int64,1};TakeAvg=0)
   
    TStackOne = zeros(Nsize, Nsize);
    UStackOne = zeros(Nsize, Nsize);
    LastID = 0; Nduplicate = 0; Noutside = 0;
    Step = 1000; percent = 10; 
    dim = length(pixelIDs)
    for j = 1:dim   # pixel index of a supercluster
        if (pixelIDs[j] != LastID) & (pixelIDs[j] > 0)
            LastID = pixelIDs[j]
            if (planck_map[pixelIDs[j]] > Tmin) & (planck_map[pixelIDs[j]] < Tmax) # exlude the masked regions
                θ, ϕ = pixelfunc.pix2ang(NSIDE,pixelIDs[j])
                if ϕ > ϕc + dtheta
                    ϕ -= 2pi
                end
                if ϕ < ϕc - dtheta
                    ϕ += 2pi
                end
                row_shift = Int64(round( (θ - θc) /res )) 
                col_shift = Int64(round( (ϕ - ϕc) /res )) 
                TStackOne += ShiftArray(Tmap,row_shift, col_shift) * planck_map[pixelIDs[j]]
                UStackOne += ShiftArray(Umap,row_shift, col_shift)
                #if j == Step
                #    θang = θ * 180 / pi
                #    ϕang = ϕ * 180 / pi
                #    println(" (θ, ϕ)  = ($θang, $ϕang) -> ($row_shift, $col_shift) shift")
                #    Step += 1000
                #end
            else
                Noutside +=1
            end
        else
            Nduplicate +=1
        end
        if 100. * j / dim > percent
            println("   |>> $percent % is done.")
            percent += 10
        end        
    end

    println("   |>> $Nduplicate duplicate / bad pixels are found")
    println("   |>> $Noutside pixels outside Temp range are found")
    if TakeAvg == 1
        println("   |>> averaging one stacked image")

        Step = 100
        for j = 1:Nsize*Nsize
            if UStackOne[j] > 0.
                TStackOne[j] /= UStackOne[j]
            end
            #if j == Step
            #    println("Temp at $j th pixel = ",TStackOne[j]," N = ", UStackOne[j])
            #    Step += 100
            #end
        end
    end

    println("saving ""$path$targetimg""_$name""_$i_target$ext")
    np.save("$path$targetimg""_$name""_$i_target$ext",TStackOne)
end



function SpheCoord2Index2(θmin::Float64,θmax::Float64,ϕmin::Float64,ϕmax::Float64)
    
    index = Array(Int64,0)

    if θmax > 1*pi
        println("   |> θmax is greater than 179° ... set θmax = 179°")
        θmax = 179. * pi / 180.
    end
    if θmin < 0
        println("   |> θmin is smaller than 1° ... set θmin = 1°")
        θmin = pi / 180.
    end

    θ = copy(θmax);
    ϕc = ϕmin + dtheta;
    println("   |> finding pixels in the region...")
    
    if ((ϕmax > 2pi) | (ϕmin * ϕmax < 0)) 
        if ϕmax > 2pi
            ϕmax -= 2pi
        end

        if ϕmin < 0
            ϕmin += 2pi
        end

        ϕcE = (ϕmax + 0) * 0.5
        ϕcW = ( 2pi + ϕmin) * 0.5

        dangE = abs(ϕcE)
        dangW = 2pi - ϕcW


        percent = 10
        while θ > θmin
            ϕc = ϕcE
            id = pixelfunc.ang2pix(NSIDE,θ,ϕc)
            index = vcat(index, id)
            id = pixelfunc.get_all_neighbours(NSIDE,θ,ϕc)[[2,3,5,6,4]]
            l, ϕ2 = pixelfunc.pix2ang(NSIDE,id[4])
            l, ϕ1 = pixelfunc.pix2ang(NSIDE,id[1])
            index = vcat(index, id[1:4])
            id_next = id[5]
            while abs(ϕ2 - ϕ1) < 2dangE
                ind2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ2)[[5,6]]
                ind1 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ1)[[2,3]]
                index = vcat(index,ind1,ind2)     
                l, ϕ2 = pixelfunc.pix2ang(NSIDE,ind2[2])   
                l, ϕ1 = pixelfunc.pix2ang(NSIDE,ind1[1])
            end

            ϕc = ϕcW
            id = pixelfunc.ang2pix(NSIDE,θ,ϕc)
            index = vcat(index, id)
            id = pixelfunc.get_all_neighbours(NSIDE,θ,ϕc)[[2,3,5,6,4]]
            l, ϕ2 = pixelfunc.pix2ang(NSIDE,id[4])
            l, ϕ1 = pixelfunc.pix2ang(NSIDE,id[1])
            index = vcat(index, id[1:4])
            id_next = id[5]
            while abs(ϕ2 - ϕ1) < 2dangW
                ind2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ2)[[5,6]]
                ind1 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ1)[[2,3]]
                index = vcat(index,ind1,ind2)     
                l, ϕ2 = pixelfunc.pix2ang(NSIDE,ind2[2])   
                l, ϕ1 = pixelfunc.pix2ang(NSIDE,ind1[1])
            end            

            if (θmax - θ) / dtheta * 50 > percent
                println("   |>> $percent % is done.")
                percent += 10
            end

            θ, b = pixelfunc.pix2ang(NSIDE,id_next)
        end        

    else
        #(SW, W, NW, N, NE, E, SE and S )
        percent = 10
        while θ > θmin
            id = pixelfunc.ang2pix(NSIDE,θ,ϕc)
            index = vcat(index, id)
            id = pixelfunc.get_all_neighbours(NSIDE,θ,ϕc)[[2,3,5,6,4]]
            l, ϕ2 = pixelfunc.pix2ang(NSIDE,id[4])
            l, ϕ1 = pixelfunc.pix2ang(NSIDE,id[1])
            index = vcat(index, id[1:4])
            id_next = id[5]
            while abs(ϕ2 - ϕ1) < 2dtheta
                ind2 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ2)[[5,6]]
                ind1 = pixelfunc.get_all_neighbours(NSIDE,θ,ϕ1)[[2,3]]
                index = vcat(index,ind1,ind2)     
                l, ϕ2 = pixelfunc.pix2ang(NSIDE,ind2[2])   
                l, ϕ1 = pixelfunc.pix2ang(NSIDE,ind1[1])
            end
            
            if (θmax - θ) / dtheta * 50 > percent
                println("   |>> $percent % is done.")
                percent += 10
            end

            θ, b = pixelfunc.pix2ang(NSIDE,id_next)
        end
    end

    println("   |> Choosing possible pixel indices in the region is done.")
    println("   |> sorting index")
    index     = sort(index)
    return length(index), index
end



