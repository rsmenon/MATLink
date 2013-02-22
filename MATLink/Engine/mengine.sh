#!/bin/sh

engdir=`dirname $0`

MATLAB=`cat $engdir/matlab_path`

export DYLD_LIBRARY_PATH=$MATLAB/bin/maci64:$DYLD_LIBRARY_PATH
export PATH=$MATLAB/bin:$PATH

$engdir/mengine $@
