

#include "mengine.h"

#include <string.h>
#include <stdlib.h>

void engsetReal(char *name) {
	double *data;
	int    *dims;
	char  **heads;
	int     rank;

	size_t size;
	int i;

	mxArray *mlarr;
	mwSize  *mldims;

	if (! MLGetReal64Array(stdlink, &data, &dims, &heads, &rank)) {
		// TODO error message

		MLPutSymbol(stdlink, "$Failed");
		return;
	}

	mldims = malloc(rank * sizeof(mwSize));
	size = 1;
	for (i=0; i < rank; ++i) {
		mldims[rank - i - 1] = dims[i];
		size *= dims[i];
	}

	mlarr = mxCreateNumericArray(rank, mldims, mxDOUBLE_CLASS, mxREAL);

	memcpy((void *) (mxGetPr(mlarr)), (void *) data, size * sizeof(double));

	engPutVariable(Eng, name, mlarr);

	free(mldims);
	MLReleaseReal64Array(stdlink, data, dims, heads, rank);

	MLPutSymbol(stdlink, "Null");
}


void engsetComplex(char *name) {
	// Need to keep separate vars for Real and Imag
	// so memory can be freed for both
	double *dataReal;
	double *dataImag;
	int    *dimsReal;
	int    *dimsImag;
	char  **headsReal;
	char  **headsImag;
	int     rank;

	size_t size;
	int i;

	mxArray *mlarr;
	mwSize  *mldims;

	if (! MLGetReal64Array(stdlink, &dataReal, &dimsReal, &headsReal, &rank)) {
		// TODO error message

		MLPutSymbol(stdlink, "$Failed");
		return;
	}


	if (! MLGetReal64Array(stdlink, &dataImag, &dimsImag, &headsImag, &rank)) {
		// TODO error message
		// TODO free mem for real

		MLPutSymbol(stdlink, "$Failed");
		return;
	}

	// TODO verify that real and imag are consistent

	mldims = malloc(rank * sizeof(mwSize));
	size = 1;
	for (i=0; i < rank; ++i) {
		mldims[rank - i - 1] = dimsReal[i];
		size *= dimsReal[i];
	}

	mlarr = mxCreateNumericArray(rank, mldims, mxDOUBLE_CLASS, mxCOMPLEX);

	memcpy((void *) (mxGetPr(mlarr)), (void *) dataReal, size * sizeof(double));
	memcpy((void *) (mxGetPi(mlarr)), (void *) dataImag, size * sizeof(double));

	engPutVariable(Eng, name, mlarr);

	free(mldims);
	MLReleaseReal64Array(stdlink, dataReal, dimsReal, headsReal, rank);
	MLReleaseReal64Array(stdlink, dataImag, dimsImag, headsImag, rank);

	MLPutSymbol(stdlink, "Null");
}
