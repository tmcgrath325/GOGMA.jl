import Base: eltype, length, size, convert, promote_rule


abstract type AbstractGaussian{T<:Real,N} end
# leaving the possibility open for adding anisotropic Gaussians

abstract type AbstractGMM{T<:Real,N} end
abstract type AbstractSingleGMM{T<:Real,N} <: AbstractGMM{T,N} end
abstract type AbstractMultiGMM{T<:Real,N,K} <: AbstractGMM{T,N} end

"""
A structure that defines an isotropic Gaussian distribution with the location of the mean, `μ`, standard deviation `σ`, 
and scaling factor `ϕ`. 

An `IsotropicGaussian` can also be assigned directions `dirs` which enforce a penalty for misalignment with the `dirs` of 
another `IsotropicGaussian`.
"""
struct IsotropicGaussian{T<:Real,N} <: AbstractGaussian{T,N}
    μ::SVector{N,T}
    σ::T
    ϕ::T
    dirs::Vector{SVector{N,T}}
end
eltype(::IsotropicGaussian{T,N}) where {T,N} = T
length(::IsotropicGaussian{T,N}) where {T,N} = N
size(::IsotropicGaussian{T,N}) where {T,N} = (N,)
size(::IsotropicGaussian{T,N}, idx::Int) where {T,N} = (N,)[idx]

function IsotropicGaussian(μ::AbstractArray, σ::Real, ϕ::Real, dirs::AbstractArray=SVector{length(μ),eltype(μ)}[])
    t = promote_type(eltype(μ), typeof(σ), typeof(ϕ), eltype(eltype(dirs)))
    return IsotropicGaussian{t,length(μ)}(SVector{length(μ),t}(μ), t(σ), t(ϕ), SVector{length(μ),t}[SVector{length(μ),t}(dir/norm(dir)) for dir in dirs])
end

convert(t::Type{IsotropicGaussian{T,N}}, g::IsotropicGaussian) where {T,N} = t(g.μ, g.σ, g.ϕ, g.dirs)
IsotropicGaussian{T,N}(g::IsotropicGaussian) where {T,N} = convert(IsotropicGaussian{T,N}, g)
promote_rule(::Type{IsotropicGaussian{T,N}}, ::Type{IsotropicGaussian{S,N}}) where {T<:Real,S<:Real,N} = IsotropicGaussian{promote_type(T,S),N}


"""
A collection of `IsotropicGaussian`s, making up a Gaussian Mixture Model (GMM).
"""
struct IsotropicGMM{T<:Real,N} <: AbstractSingleGMM{T,N}
    gaussians::Vector{IsotropicGaussian{T,N}}
end
eltype(::IsotropicGMM{T,N}) where {T,N} = T
length(gmm::IsotropicGMM) = length(gmm.gaussians)
size(gmm::IsotropicGMM{T,N}) where {T,N} = (length(gmm.gaussians), N)
size(gmm::IsotropicGMM{T,N}, idx::Int) where {T,N} = (length(gmm.gaussians), N)[idx]

convert(t::Type{IsotropicGMM{T,N}}, gmm::IsotropicGMM) where {T,N} = t(gmm.gaussians)
IsotropicGMM{T,N}(gmm::IsotropicGMM) where {T,N} = convert(IsotropicGMM{T,N}, gmm)
promote_rule(::Type{IsotropicGMM{T,N}}, ::Type{IsotropicGMM{S,N}}) where {T,S,N} = IsotropicGMM{promote_type(T,S),N}

"""
A collection of labeled `IsotropicGMM`s, to each be considered separately during an alignment procedure. That is, 
only alignment scores between `IsotropicGMM`s with the same key are considered when aligning two `MultiGMM`s. 
"""
struct IsotropicMultiGMM{T<:Real,N,K} <: AbstractMultiGMM{T,N,K}
    gmms::Dict{K, IsotropicGMM{T,N}}
end
eltype(::IsotropicMultiGMM{T,N,K}) where {T,N,K} = T
length(mgmm::IsotropicMultiGMM) = length(mgmm.gmms)
size(mgmm::IsotropicMultiGMM{T,N,K}) where {T,N,K} = (length(mgmm.gmms), N)
size(mgmm::IsotropicMultiGMM{T,N,K}, idx::Int) where {T,N,K} = (length(mgmm.gmms), N)[idx]

convert(t::Type{IsotropicMultiGMM{T,N,K}}, mgmm::IsotropicMultiGMM) where {T,N,K} = t(mgmm.gmms)
IsotropicMultiGMM{T,N,K}(mgmm::IsotropicMultiGMM) where {T,N,K} = convert(IsotropicMultiGMM{T,N}, mgmm)
promote_rule(::Type{IsotropicMultiGMM{T,N,K}}, ::Type{IsotropicMultiGMM{S,N,K}}) where {T,S,N,K} = IsotropicMultiGMM{promote_type(T,S),N,K}

# descriptive display
# TODO update to display type parameters, make use of supertypes, etc

Base.show(io::IO, g::IsotropicGaussian) = println(io,
    "IsotropicGaussian with mean $(g.μ), standard deviation $(g.σ), and weight $(g.ϕ),\n",
    " with $(length(g.dirs)) directional constraints."
)

Base.show(io::IO, gmm::IsotropicGMM) = println(io,
    "IsotropicGMM with $(length(gmm)) Gaussian distributions."
)

Base.show(io::IO, mgmm::IsotropicMultiGMM) = println(io,
    "MultiGMM with $(length(mgmm)) IsotropicGMMs and a total of $(sum([length(gmm) for (key,gmm) in mgmm.gmms])) IsotropicGaussians."
)