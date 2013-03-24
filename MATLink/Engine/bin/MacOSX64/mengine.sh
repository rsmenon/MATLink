#!/bin/sh

# Before using mEngine, you need to
# set the path to your MATLAB installation here:
# MATLAB=/Applications/MATLAB_2013a.app
MATLAB=`ls -d /Applications/MATLAB*.app | tail -n 1`

export DYLD_LIBRARY_PATH=$MATLAB/bin/maci64:$DYLD_LIBRARY_PATH
export PATH=$MATLAB/bin:$PATH

$(dirname $0)/mengine $@
