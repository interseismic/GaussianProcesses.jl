#This file contains a list of the currently available mean functions

import Distributions.params

abstract Mean

include("mConst.jl")
include("mLin.jl")
include("mPoly.jl")