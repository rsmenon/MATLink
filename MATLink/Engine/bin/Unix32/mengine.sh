#!/bin/sh

MATLAB=$(dirname `which matlab`)/..
MATHLINK=$(dirname `which math`)/../SystemFiles/Links/MathLink/DeveloperKit/Linux/CompilerAdditions


export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MATLAB/bin/glnxa32/:$MATHLINK

$(dirname $0)/mengine $@
