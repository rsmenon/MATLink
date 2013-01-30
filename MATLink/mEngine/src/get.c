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
void toMma(const mxArray *matlabVar, MLINK link) {
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


	// numerical; TODO handle single precision and other types
	if (mxIsDouble(matlabVar)) {
		double *Pr = NULL;	//pointer to real
		double *Pi = NULL;	//pointer to imaginary

		//data pointer
		Pr = mxGetPr(matlabVar);
		Pi = mxGetPi(matlabVar);

		MLPutFunction(link, "Transpose", 2);
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
		MLPutFunction(link, "PermutationList",1);
		MLPutFunction(link, "Cycles", 1);
		MLPutFunction(link, "List", 1);
		{
			int tr[2];
			tr[0] = depth;
			tr[1] = depth-1;
			MLPutInteger32List(link, tr, 2);
		}
	}
	// char array (string); TODO handle multidimensional char arrays
	else if (mxIsChar(matlabVar)) {
		char *str;

		str = mxArrayToString(matlabVar);
		MLPutUTF8String(link, (unsigned char *) str, strlen(str));
		mxFree(str);
	}
	// unknown or failure; TODO distinguish between unknown and failure
	else
	{
		MLPutSymbol(link, "$Failed");
	}

	free(mmaDims);
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

	/*
	if ( toMma(MxVar, stdlink) ) { // failure
		msg("engGet::ertp");
		SUCCESS = false;
		goto epilog;
	}*/
	toMma(MxVar, stdlink);

epilog:
	// cleanup
	if(NULL != MxVar)
		mxDestroyArray(MxVar);		
	if (! SUCCESS)
		MLPutSymbol(stdlink, "$Failed");
}

