/* main.cpp
 *
 * Copyright (c) 2013 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
 */

#include "mengine.h"


// mex -v LDFLAGS="\$LDFLAGS -framework Foundation" main.cpp get.cpp set.cpp mengine.cpp menginetm.cpp -L'/Applications/Mathematica.app/SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/' -I'/Applications/Mathematica.app/SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/' -lMLi3 -output StartMATLink

#include "mengine.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    (void) plhs; (void) prhs;    /* unused parameters */

    /* Check for proper number of input and output arguments */
    if (nrhs !=0) {
        mexErrMsgIdAndTxt( "MATLAB:mxisclass:maxrhs",
                "No input argument required.");
    }
    if(nlhs > 1){
        mexErrMsgIdAndTxt( "MATLAB:mxisclass:maxlhs", "Too many outputs");
    }
    MLMainString("-mathlink -linkmode listen linkprotocol SharedMemory -linkname MatlabLink");
}


