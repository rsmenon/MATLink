#!/bin/sh

# Linux 64 bit MATLink start script
# Modify the variables below to use a custom MATLAB installation:

MATLAB=$(dirname $(readlink -f $(which matlab)))/..
MATHLINK=$(dirname $(readlink -f $(which math)))/../SystemFiles/Links/MathLink/DeveloperKit/Linux-x86-64/CompilerAdditions

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MATLAB/bin/glnxa64/:$MATHLINK

$(dirname $0)/mengine $@
