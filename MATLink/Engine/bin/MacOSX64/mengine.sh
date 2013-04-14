#!/bin/sh

# OS X MATLink start script
#
# This script will look for MATLAB installations mathching /Applications/MATLAB*.app
# If you have MATLAB installed in a different location or you need to use
# a specific version of MATLAB, uncomment the following line and set the path
# to the MATLAB app bundle you wish to use:
#
# MATLAB=/Applications/MATLAB_R2013a.app

# If you set the MATLAB path manually, comment out the following line:
MATLAB=`ls -d /Applications/MATLAB*.app | tail -n 1`


export DYLD_LIBRARY_PATH=$MATLAB/bin/maci64:$DYLD_LIBRARY_PATH
export PATH=$MATLAB/bin:$PATH

$(dirname $0)/mengine $@
