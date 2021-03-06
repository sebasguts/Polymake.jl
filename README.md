# Polymake.jl

[![Build Status](https://travis-ci.com/oscar-system/Polymake.jl.svg?branch=master)](https://travis-ci.com/oscar-system/Polymake.jl)

Julia package for using [polymake](https://polymake.org/doku.php), a software for research in polyhedral geometry.
This package is developed as part of the [OSCAR](https://oscar.computeralgebra.de) project.

## Installation

The installation can be done in the Julia REPL by first pressing `]` and then
```julia
pkg> add https://github.com/oscar-system/Polymake.jl
```
This will fetch a pre-build binary of `polymake`. You are ready to start `using Polymake`.

### Your own installation of `polymake`

If you already have a recent enough version of polymake on your system, you either need to make `polymake-config` available in your `PATH` or the environment variable `POLYMAKE_CONFIG` needs to point to the correct `polymake-config` file.

After this just `add` the package url as above, the build script will use your `polymake` installation.

### `polymake` from source

The current version of `Polymake.jl` relies on an unreleased version of polymake. A compatible version is available at [polymake/polymake#snapshots](https://github.com/polymake/polymake/tree/Snapshots).
It can be compiled as follows where `GIT_FOLDER` and `INSTALL_FOLDER` have to be substituted with your favorite folders. Please note that these need to be absolute paths.
Also make sure to check [the necessary dependencies](https://polymake.org/doku.php/howto/install) as well as the [additional instructions for Macs](https://polymake.org/doku.php/howto/mac).
```sh
export POLYMAKE_GIT=GIT_FOLDER
export POLYMAKE_INSTALL=INSTALL_FOLDER
git clone git@github.com:polymake/polymake $POLYMAKE_GIT
cd $POLYMAKE_GIT
git checkout Snapshots
./configure --prefix=$POLYMAKE_INSTALL
ninja -C build/Opt
ninja -C build/Opt install
export POLYMAKE_CONFIG=$POLYMAKE_INSTALL/bin/polymake-config
```
Note that polymake might take some time to compile.

After this start `julia` and just `add` the `Polymake.jl` from url as above.

### `Polymake.jl` in a separate environment:
First clone `Polymake.jl`:
```
git clone https://github.com/oscar-system/Polymake.jl.git
```
In Julia REPL press `]` for `pkg` mode and 
```julia
(v1.0) pkg> activate Polymake.jl
(Polymake) pkg> instantiate
(Polymake) pkg> build Polymake # fetches the prebuild polymake binaries
(Polymake) pkg> test Polymake # and You are good to go!
```
If `polymake-config` is in your `PATH`, or `POLYMAKE_CONFIG` environment variable is set the `build` phase will try to use it.

Just remember that You need to `activate Polymake.jl` to use `Polymake`.

## Examples

polymake big objects (like `Polytope`, `Cone`, etc) can be created with the `perlobj` helper functions.
```julia
# Call the Polytope constructor
julia> p = perlobj("Polytope", POINTS=[1 -1 -1; 1 1 -1; 1 -1 1; 1 1 1; 1 0 0])
type: Polytope<Rational>

POINTS
1 -1 -1
1 1 -1
1 -1 1
1 1 1
1 0 0

```

Properties of such objects can be accessed by the `.` syntax
```
julia> p.INTERIOR_LATTICE_POINTS
pm::Matrix<pm::Integer>
1 0 0
```

## Current state

### Data structures

* Several small data types from polymake are available in Julia:
    * Integers
    * Rationals
    * Vectors
    * Matrices
    * Arrays
    * Sets
    * Combinations thereof, e.g., Sets of Arrays of Integers
 
The polymake data types can be converted to appropriate Julia types,
but are also subtypes of the corresponding Julia abstract types, e.g., a
polymake array is an `AbstractArray`, and one can call methods that
apply to `AbstractArray`s on polymake arrays.
* Big objects, e.g., Polytopes, can be handled in Julia

### Functions

* Properties of big objects are accessible by `object.property` syntax
(and also via the `give` function).
* Methods can be called via `call_method`
* Functions can be called via `call_function`

All three ways of calling a function in polymake can return any big or
small object, and the generic return (`PropertyValue`) is transparently
converted to one of the data types above. For performance reasons, this
conversion can be deactivated
