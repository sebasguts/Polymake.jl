module PolymakeWrap

module Polymake
    using CxxWrap
    pm_dir = Pkg.dir("PolymakeWrap", "deps", "src","libpolymake.so")
    wrap_module(pm_dir,Polymake)
end

import Base: promote_rule

import .Polymake: pm_Integer, pm_Rational, pm_Vector, pm_Matrix, exists, new_pm_Integer,
                 numerator, denominator, application

function __init__()
    Polymake.init()
    Polymake.application("polytope")
end

SmallObject = Union{pm_Integer,
                    pm_Rational,
                    pm_Matrix,
                    pm_Vector}

BuiltIn = Union{Int64,
                Int32}

const to_value = Polymake.to_value

promote_rule(::Type{Polymake.pm_perl_Value},::Type{SmallObject}) = Polymake.pm_perl_Value
promote_rule(::Type{Polymake.pm_perl_Value},::Type{BuiltIn}) = Polymake.pm_perl_Value

include("functions.jl")
include("convert.jl")

end