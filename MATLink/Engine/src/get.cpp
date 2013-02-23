
#include "mengine.h"


// Takes a MATLAB variable and writes in in Mathematica form to link
void toMma(const mxArray *var, MLINK link) {

    // the following may occur when retrieving empty struct fields
    // it showsup as [] in MATLAB so we return {}
    // note that non-existent variables are caught and handled in eng_get()
    if (var == NULL) {
        MLPutFunction(link, "List", 0);
        return;
    }

    // get size information
    mwSize depth = mxGetNumberOfDimensions(var);
    const mwSize *mbDims = mxGetDimensions(var);

    // handle zero-size arrays
    if (mxIsEmpty(var)) {
        MLPutFunction(link, "List", 0);
        return;
    }

    //translate dimension information to Mathematica
    int mmDims[depth];
    for (int i=0; i < depth; ++i)
        mmDims[i] = mbDims[depth - 1 - i];

    // numerical; TODO handle single precision and other types
    if (mxIsDouble(var)) {
        if (mxIsSparse(var)) {

            int ncols = mxGetN(var); // number of columns

            double *real = mxGetPr(var);
            double *imag = mxGetPi(var);

            mwIndex *jc = mxGetJc(var);
            mwIndex *ir = mxGetIr(var);

            int nnz = jc[ncols]; // number of nonzeros

            MLPutFunction(link, CONTEXT "matSparseArray", 4);
            mlpPutIntegerList(link, jc, ncols + 1);
            mlpPutIntegerList(link, ir, nnz);
            if (mxIsComplex(var)) {
                MLPutFunction(link, "Plus", 2);
                MLPutReal64List(link, real, nnz);
                MLPutFunction(link, "Times", 2);
                MLPutReal64List(link, imag, nnz);
                MLPutSymbol(link, "I");
            }
            else { // real only
                MLPutReal64List(link, real, nnz);
            }
            MLPutInteger32List(link, mmDims, depth);
        }
        else // not sparse
        {
            double *real = mxGetPr(var);    // pointer to real
            double *imag = mxGetPi(var);    // pointer to imaginary

            if (real == NULL) {
                MLPutSymbol(link, "$Failed"); // TODO report error
                return;
            }

            if (mxIsComplex(var) && imag == NULL) {
                MLPutSymbol(link, "$Failed"); // TODO report error
                return;
            }

            MLPutFunction(link, CONTEXT "matArray", 2);
            if (mxIsComplex(var)) {
                //output re+im*I
                MLPutFunction(link, "Plus", 2);
                MLPutReal64Array(link, real, mmDims, NULL, depth);
                MLPutFunction(link, "Times", 2);
                MLPutReal64Array(link, imag, mmDims, NULL, depth);
                MLPutSymbol(link, "I");
            }
            else {
                MLPutReal64Array(link, real, mmDims, NULL, depth);
            }
            MLPutInteger32List(link, mmDims, depth);
        }
    }
    else if (mxIsLogical(var)) {
        mxLogical *logicals = mxGetLogicals(var);
        int len = mxGetNumberOfElements(var);

        int intarr[len]; // TODO don't alloc on stack
        for (int i=0; i < len; ++i)
            if (logicals[i])
                intarr[i] = 1;
            else
                intarr[i] = 0;

        MLPutFunction(link, CONTEXT "matLogical", 2);
        MLPutInteger32Array(link, intarr, mmDims, NULL, depth);
        MLPutInteger32List(link, mmDims, depth);
    }
    // char array (string); TODO handle multidimensional char arrays
    else if (mxIsChar(var)) {
        mxChar *str = mxGetChars(var);
        MLPutFunction(link, CONTEXT "matString", 1);
        MLPutUTF16String(link, str, mxGetNumberOfElements(var)); // cast may be required on other platforms: (mxChar *) str
    }
    // struct
    else if (mxIsStruct(var)) {
        int len = mxGetNumberOfElements(var);
        int nfields = mxGetNumberOfFields(var);
        MLPutFunction(link, CONTEXT "matStruct", 2);
        MLPutFunction(link, "List", len);
        for (int j=0; j < len; ++j) {
            MLPutFunction(link, "List", nfields);
            for (int i=0; i < nfields; ++i) {
                const char *fieldname;

                fieldname = mxGetFieldNameByNumber(var, i);
                MLPutFunction(link, "Rule", 2);
                MLPutString(link, fieldname);
                toMma(mxGetFieldByNumber(var, j, i), link);
            }
        }
        MLPutInteger32List(link, mmDims, depth);
    }
    // cell
    else if (mxIsCell(var)) {
        int len = mxGetNumberOfElements(var);
        MLPutFunction(link, CONTEXT "matCell", 2);
        MLPutFunction(link, "List", len);
        for (int i=0; i < len; ++i)
            toMma(mxGetCell(var, i), link);
        MLPutInteger32List(link, mmDims, depth);
    }
    // unknown or failure; TODO distinguish between unknown and failure
    else
    {
        const char *classname = mxGetClassName(var);
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

