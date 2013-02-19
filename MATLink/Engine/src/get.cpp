
#include "mengine.h"

#include <iostream>
#include <fstream>
#include <cstring>

using namespace std;

// Takes a MATLAB variable and writes in in Mathematica form to link
// To be used with loopback links
void toMma(const mxArray *matlabVar, MLINK link) {

    // the following may occur when retrieving empty struct fields
    // it showsup as [] in MATLAB so we return {}
    // note that non-existent variables are caught and handled in eng_get()
    if (matlabVar == NULL) {
        MLPutFunction(link, "List", 0);
        return;
    }

    // get size information
    mwSize depth = mxGetNumberOfDimensions(matlabVar);
    const mwSize *matlabDims = mxGetDimensions(matlabVar);

    // handle zero-size arrays
    for (int i=0; i < depth; ++i)
        if (matlabDims[i] == 0) {
            MLPutFunction(link, "List", 0);	// temporary workaround for empty array, just return {};  TODO fix
            return;
        }

    //translate dimension information to Mathematica
    int mmaDims[depth];
    for (int i=0; i < depth; ++i)
        mmaDims[i] = matlabDims[depth - 1 - i];

    // numerical; TODO handle single precision and other types
    if (mxIsDouble(matlabVar)) {
        if (mxIsSparse(matlabVar)) {

            int ncols = mxGetN(matlabVar); // number of columns

            double *Pr = mxGetPr(matlabVar);
            double *Pi = mxGetPi(matlabVar);

            mwIndex *Jc = mxGetJc(matlabVar);
            mwIndex *Ir = mxGetIr(matlabVar);

            int nnz = Jc[ncols]; // number of nonzeros

            MLPutFunction(link, CONTEXT "matSparseArray", 4);
            mlpPutIntegerList(link, Jc, ncols + 1);
            mlpPutIntegerList(link, Ir, nnz);
            if (mxIsComplex(matlabVar)) {
                MLPutFunction(link, "Plus", 2);
                MLPutReal64List(link, Pr, nnz);
                MLPutFunction(link, "Times", 2);
                MLPutReal64List(link, Pi, nnz);
                MLPutSymbol(link, "I");
            }
            else { // real only
                MLPutReal64List(link, Pr, nnz);
            }
            MLPutInteger32List(link, mmaDims, depth);
        }
        else // not sparse
        {
            double *Pr = mxGetPr(matlabVar);    // pointer to real
            double *Pi = mxGetPi(matlabVar);    // pointer to imaginary

            if (Pr == NULL) {
                MLPutSymbol(link, "$Failed"); // TODO report error
                return;
            }

            if (mxIsComplex(matlabVar) && Pi == NULL) {
                MLPutSymbol(link, "$Failed"); // TODO report error
                return;
            }

            MLPutFunction(link, CONTEXT "matArray", 2);
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
            MLPutInteger32List(link, mmaDims, depth);
        }
    }
    else if (mxIsLogical(matlabVar)) {
        mxLogical *logarr = mxGetLogicals(matlabVar);
        int len = mxGetNumberOfElements(matlabVar);

        int intarr[len]; // TODO don't alloc on stack
        for (int i=0; i < len; ++i)
            if (logarr[i])
                intarr[i] = 1;
            else
                intarr[i] = 0;

        MLPutFunction(link, CONTEXT "matLogical", 2);
        MLPutInteger32Array(link, intarr, mmaDims, NULL, depth);
        MLPutInteger32List(link, mmaDims, depth);
    }
    // char array (string); TODO handle multidimensional char arrays
    else if (mxIsChar(matlabVar)) {        
        mxChar *str = mxGetChars(matlabVar);
        MLPutFunction(link, CONTEXT "matString", 1);
        MLPutUTF16String(link, str, mxGetNumberOfElements(matlabVar)); // cast may be required on other platforms: (mxChar *) str
    }
    // struct
    else if (mxIsStruct(matlabVar)) {
        int len = mxGetNumberOfElements(matlabVar);
        int nfields = mxGetNumberOfFields(matlabVar);
        MLPutFunction(link, CONTEXT "matStruct", 2);
        MLPutFunction(link, "List", len);
        for (int j=0; j < len; ++j) {
            MLPutFunction(link, "List", nfields);
            for (int i=0; i < nfields; ++i) {
                const char *fieldname;

                fieldname = mxGetFieldNameByNumber(matlabVar, i);
                MLPutFunction(link, "Rule", 2);
                MLPutString(link, fieldname);
                toMma(mxGetFieldByNumber(matlabVar, j, i), link);
            }
        }
        MLPutInteger32List(link, mmaDims, depth);
    }
    // cell
    else if (mxIsCell(matlabVar)) {
        int len = mxGetNumberOfElements(matlabVar);
        MLPutFunction(link, CONTEXT "matCell", 2);
        MLPutFunction(link, "List", len);
        for (int i=0; i < len; ++i)
            toMma(mxGetCell(matlabVar, i), link);
        MLPutInteger32List(link, mmaDims, depth);
    }
    // unknown or failure; TODO distinguish between unknown and failure
    else
    {
        const char *classname = mxGetClassName(matlabVar);
        MLPutFunction(link, CONTEXT "matUnknown", 1);
        MLPutString(link, classname);
    }
}


void eng_get(const char *name) {
    mxArray *var = engine.getVariable(name);
    if (var == NULL)
        MLPutSymbol(stdlink, "$Failed");
    else {
        toMma(var, stdlink);
        mxDestroyArray(var);
    }
}

