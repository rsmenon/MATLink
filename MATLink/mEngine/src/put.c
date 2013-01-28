/*
 * put.c
 *
 * Wrapper of the MatLab Engine API engPutVariable
 * for call from Mathematica
 *
 * Revision 2003.3.11
 *
 * Robert
 *	
 */

#include "mengine.h"

#include <string.h>


// put a real array to the MatLab workspace
void engputr(const char* VarName,
		     const int* mmaDim, int Depth,
		     const double* Val, int ValLen)
{
	mxArray* MxVar = NULL;		//the variable to be put
	bool SUCCESS = true;		//success flag
	int i;						// generic iterator

	mwSize matlabDim[Depth];	// dimensions array in MATLAB format

	for (i=0; i < Depth; ++i)
		matlabDim[i] = (mwSize) mmaDim[i];

	if (NULL == Eng)	//if not opened yet
	{
		msg("eng::noMLB");	//message 
		SUCCESS = false;
		goto epilog;
	}
	
	//create mxArray 
	MxVar = mxCreateNumericArray(Depth, matlabDim, mxDOUBLE_CLASS, mxREAL);
	if (NULL == MxVar)
	{
		msg("engPut::ercrt");
		SUCCESS = false;
		goto epilog;
	}
	//and populate
	memcpy((void *)(mxGetPr(MxVar)), (void *)Val, ValLen * sizeof(double));
	
	//put
	if(engPutVariable(Eng, VarName, MxVar))	//not successful
	{
		msg("engPut::erput");
		SUCCESS = false;
		goto epilog;
	}
	
epilog:
	if (MxVar != NULL)
		mxDestroyArray(MxVar);

	if(SUCCESS)
		MLPutString(stdlink, VarName);
	else
		MLPutSymbol(stdlink, "$Failed");
}

//put a complex array
void engputc(const char* VarName,
		     const int* mmaDim, int Depth,
		     const double* Re, int ReLen,
		     const double* Im, int ImLen)
{
	mxArray* MxVar = NULL;		//the variable to be put
	bool SUCCESS = true;		//success flag
	int i;						// generic iterator

	mwSize matlabDim[Depth];	// dimensions array in MATLAB format

	for (i=0; i < Depth; ++i)
		matlabDim[i] = (mwSize) mmaDim[i];


	if (NULL == Eng)	//if not opened yet, open it
	{
		msg("eng::noMLB");	//message 
		SUCCESS = false;
		goto epilog;
	}
	
	//create mxArray 
	MxVar = mxCreateNumericArray(Depth, matlabDim, mxDOUBLE_CLASS, mxCOMPLEX);
	if (NULL == MxVar)
	{
		msg("engPut::ercrt");
		SUCCESS = false;
		goto epilog;
	}
	//and populate
	memcpy((void *)(mxGetPr(MxVar)), (void *)Re, ReLen * sizeof(double));
	memcpy((void *)(mxGetPi(MxVar)), (void *)Im, ImLen * sizeof(double));

	//put
	if(engPutVariable(Eng, VarName, MxVar))	//not successful
	{
		msg("engPut::erput");
		SUCCESS = false;
		goto epilog;
	}
	
epilog:
	if (MxVar != NULL)
		mxDestroyArray(MxVar);

	if(SUCCESS)
		MLPutString(stdlink, VarName);
	else
		MLPutSymbol(stdlink, "$Failed");
}

