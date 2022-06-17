using GaussianMixtureAlignment
using StaticArrays
using CoordinateTransformations
using Rotations
# Note: ProfileView and BenchmarkTools are not added by this package
using ProfileView
using BenchmarkTools

# small problem
xcoords = hcat([[0.,0.,0.], [3.,0.,0.,], [0.,4.,0.]]...);
ycoords = hcat([[1.,1.,1.], [1.,-2.,1.], [1.,1.,-3.]]...);
weights = [1.,1.,1.];
xset = PointSet(xcoords, weights);
yset = PointSet(ycoords, weights);

@btime goih_align(xset, yset; maxsplits=100);
@btime tiv_goih_align(xset, yset; maxsplits=100);
# @ProfileView.profview goih_align(xset, yset; maxsplits=1000);
# @ProfileView.profview tiv_goih_align(xset, yset; maxsplits=1000);

# larger problem
randpts = 25*rand(3,50) .- 50;
randtform = AffineMap(RotationVec(π*rand(3)...), SVector{3}(5*rand(3)...));
weights = ones(Float64, 50);
xset = PointSet(randpts, weights);
yset = PointSet(randtform(randpts), weights);

@ProfileView.profview goih_align(xset, yset; maxsplits=100);
@ProfileView.profview tiv_goih_align(xset, yset, 2, 2; maxsplits=100);
@time goih_align(xset, yset)
@time tiv_goih_align(xset, yset, 2, 2)
