loose_distance_bounds(x<:SVector{3,Number}, y<:SVector{3,Number}, σᵣ<:Number, σₜ<:Number) = (norm(x - y), max(ubdist - σᵣ - σₜ, 0))
loose_distance_bounds(x<:SVector{3}, y<:SVector{3}, R::RotationVec, T<:SVector{3}, σᵣ, σₜ) = loose_distance_bounds(R*x, y-T, σᵣ, σₜ)
loose_distance_bounds(x<:SVector{3}, y<:SVector{3}, block::UncertaintyRegion) = loose_distance_bounds(x, y, block.R, block.T, block.σᵣ, block.σₜ)
loose_distance_bounds(x<:SVector{3}, y<:SVector{3}, block::SearchRegion) = loose_distance_bounds(x, y, UncertaintyRegion(block))


"""
    lb, ub = tight_distance_bounds(x::SVector{3,Number}, y::SVector{3,Number}, σᵣ<:Number, σₜ<:Number)
    lb, ub = tight_distance_bounds(x::SVector{3,Number}, y::SVector{3,Number}, R::RotationVec, T<:SVector{3}, σᵣ<:Number, σₜ<:Number)

Within an uncertainty region, find the bounds on distance between two points x and y.

See [Campbell & Peterson, 2016](https://arxiv.org/abs/1603.00150)
"""
function tight_distance_bounds(x<:SVector{3,Number}, y<:SVector{3,Number}, σᵣ<:Number, σₜ<:Number)
    # prepare positions and angles
    xnorm, ynorm = norm(x), norm(y)
    if xnorm*ynorm == 0
        cosα = one(promote_type(eltype(x),eltype(y)))
    else
        cosα = dot(x, y)/(xnorm*ynorm) 
    end
    cosβ = cos(min(sqrt3*σᵣ/2, π))

    # upper bound distance at hypercube center
    ubdist = norm(x - y)
    
    # lower bound distance from the nearest point on the "spherical cap"
    if cosα >= cosβ
        lbdist = max(abs(xnorm-ynorm) - sqrt3*σₜ/2, 0)
    else
        lbdist = try max(√(xnorm^2 + ynorm^2 - 2*xnorm*ynorm*(cosα*cosβ+√((1-cosα^2)*(1-cosβ^2)))) - sqrt3*σₜ/2, 0)  # law of cosines
        catch e     # when the argument for the square root is negative (within machine precision of 0, usually)
            0
        end
    end

    # evaluate objective function at each distance to get upper and lower bounds
    return (lbdist, ubdist)
end

tight_distance_bounds(x<:SVector{3,Number}, y<:SVector{3,Number}, R::RotationVec, T<:SVector{3}, σᵣ<:Number, σₜ<:Number) = tight_distance_bounds(R*x, y-T, σᵣ, σₜ)
tight_distance_bounds(x<:SVector{3}, y<:SVector{3}, block::UncertaintyRegion) = tight_distance_bounds(x, y, block.R, block.T, block.σᵣ, block.σₜ)
tight_distance_bounds(x<:SVector{3}, y<:SVector{3}, block::Union{RotationRegion, TranslationRegion}) = tight_distance_bounds(x, y, UncertaintyRegion(block))