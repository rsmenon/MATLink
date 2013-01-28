/*
 * get.c
 *
 * Wrapper of the MatLab Engine API engGetVariable
 * for call from Mathematica
 *
 * Revision 2003.3.11
 *
 * Robert
 *	
 */

#include "mengine.h"

#include <stdlib.h>		// for malloc() & free()
#include <string.h>


// Takes a MATLAB variable and writes in in Mathematica form to link
// To be used with loopback links
// Returns 0 on success
// Returns 1 on failure and may leave the link with a half-built expression
int toMma(const mxArray *matlabVar, MLINK link) {
	int err = 0; // default success

	mwSize        depth;
	const mwSize *matlabDims;
	int          *mmaDims;

	int i;

	//retrive size information
	depth = mxGetNumberOfDimensions(matlabVar);
	matlabDims = mxGetDimensions(matlabVar);

	//translate dimension information to Mathematica
	mmaDims = malloc(depth * sizeof(int));
	for(i = 0; i < depth; ++i)
		mmaDims[i] = matlabDims[depth - 1 - i];


	if (mxIsDouble(matlabVar)) {
		double *Pr = NULL;	//pointer to real
		double *Pi = NULL;	//pointer to imaginary

		//data pointer
		Pr = mxGetPr(matlabVar);
		Pi = mxGetPi(matlabVar);

		if (mxIsComplex(matlabVar)) {
			//output re+im*I
			MLPutFunction(link, "Plus", 2);
			MLPutReal64Array(link, Pr, mmaDims, NULL, depth);
			MLPutFunction(link, "Times", 2);
			MLPutReal64Array(link, Pi, mmaDims, NULL, depth);
			MLPutSymbol(link, "I");
		}
		else {
			MLPutReal64Array(link, Pr, mmaDims, NULL, depth);
		}
	}
	else if (mxIsChar(matlabVar)) {
		char *str;

		str = mxArrayToString(matlabVar);
		MLPutUTF8String(link, (unsigned char *) str, strlen(str));
		mxFree(str);
	}
	else
	{
		err = 1; // failure
	}

	free(mmaDims);

	return err; // failure
}


void engget(const char* VarName)
{
	mxArray *MxVar;				// MATLAB variable
	bool     SUCCESS = true;	// status flag
    
	if (NULL == Eng)	//if MATLAB not opened
	{
		msg("eng::noMLB");	//message no start
		SUCCESS = false;
		goto epilog;
	}

	if (NULL == (MxVar = engGetVariable(Eng, VarName)))	//get variable
	{
		msg("engGet::erget");
		SUCCESS = false;
		goto epilog;
	}

	if ( toMma(MxVar, stdlink) ) { // failure
		msg("engGet::ertp");
		SUCCESS = false;
		goto epilog;
	}

epilog:
	// cleanup
	if(NULL != MxVar)
		mxDestroyArray(MxVar);		
	if (! SUCCESS)
		MLPutSymbol(stdlink, "$Failed");
}

