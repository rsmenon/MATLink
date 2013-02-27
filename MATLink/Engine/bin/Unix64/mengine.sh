#!/bin/sh

MATLAB=$(dirname `which matlab`)/..
MATHLINK=$(dirname `which math`)/../SystemFiles/Links/MathLink/DeveloperKit/Linux-x86-64/CompilerAdditions

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MATLAB/bin/glnxa64/:$MATHLINK

$(dirname $0)/mengine $@
