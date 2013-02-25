
#include "mengine.h"

#include <algorithm>


void putUnknown(const mxArray *var, MLINK link) {
    const char *classname = mxGetClassName(var);
    MLPutFunction(link, CONTEXT "matUnknown", 1);
    MLPutString(link, classname);
}


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

    //translate dimension information to Mathematica order
    int mmDims[depth];
    std::reverse_copy(mbDims, mbDims + depth, mmDims);

    // numerical (sparse or dense)
    if (mxIsNumeric(var)) {
        mxClassID classid = mxGetClassID(var);

        // verify that var is of a supported class
        switch (classid) {
        case mxDOUBLE_CLASS:
        case mxSINGLE_CLASS:
        case mxINT16_CLASS:
        case mxINT32_CLASS:
            break;
        default:
            putUnknown(var, link);
            return;
        }

        if (mxIsSparse(var)) {
            // Note: I realised that sparse arrays can only hold double precision numerical types
            // in MATLAB R2012b.  I will leave the below implementation for single precision & integer
            // types in case future versions of MATLAB will add support for them.

            int ncols = mxGetN(var); // number of columns

            mwIndex *jc = mxGetJc(var);
            mwIndex *ir = mxGetIr(var);

            int nnz = jc[ncols]; // number of nonzeros

            MLPutFunction(link, CONTEXT "matSparseArray", 4);
            mlpPutIntegerList(link, jc, ncols + 1);
            mlpPutIntegerList(link, ir, nnz);

            // if complex, put as im*I + re
            if (mxIsComplex(var)) {
                MLPutFunction(link, "Plus", 2);
                MLPutFunction(link, "Times", 2);
                MLPutSymbol(link, "I");
                switch (classid) {
                 case mxDOUBLE_CLASS:
                    MLPutReal64List(link, mxGetPi(var), nnz); break;
                 case mxSINGLE_CLASS:
                    MLPutReal32List(link, (float *) mxGetImagData(var), nnz); break;
                 case mxINT16_CLASS:
                    MLPutInteger16List(link, (short *) mxGetImagData(var), nnz); break;
                 case mxINT32_CLASS:
                    MLPutInteger32List(link, (int *) mxGetImagData(var), nnz); break;
                 default:
                    assert(false); // should never reach here
                }
            }

            switch (classid) {
             case mxDOUBLE_CLASS:
                MLPutReal64List(link, mxGetPr(var), nnz); break;
             case mxSINGLE_CLASS:
                MLPutReal32List(link, (float *) mxGetData(var), nnz); break;
             case mxINT16_CLASS:
                MLPutInteger16List(link, (short *) mxGetData(var), nnz); break;
             case mxINT32_CLASS:
                MLPutInteger32List(link, (int *) mxGetData(var), nnz); break;
             default:
                assert(false); // should never reach here
            }

            MLPutInteger32List(link, mmDims, depth);
        }
        else // not sparse
        {
            MLPutFunction(link, CONTEXT "matArray", 2);

            // if complex, put as im*I + re
            if (mxIsComplex(var)) {
                MLPutFunction(link, "Plus", 2);
                MLPutFunction(link, "Times", 2);
                MLPutSymbol(link, "I");
                switch (classid) {
                 case mxDOUBLE_CLASS:
                    MLPutReal64Array(link, mxGetPi(var), mmDims, NULL, depth); break;
                 case mxSINGLE_CLASS:
                    MLPutReal32Array(link, (float *) mxGetImagData(var), mmDims, NULL, depth); break;
                 case mxINT16_CLASS:
                    MLPutInteger16Array(link, (short *) mxGetImagData(var), mmDims, NULL, depth); break;
                 case mxINT32_CLASS:
                    MLPutInteger32Array(link, (int *) mxGetImagData(var), mmDims, NULL, depth); break;
                 default:
                    assert(false); // should never reach here
                }
            }

            switch (classid) {
             case mxDOUBLE_CLASS:
                MLPutReal64Array(link, mxGetPr(var), mmDims, NULL, depth); break;
             case mxSINGLE_CLASS:
                MLPutReal32Array(link, (float *) mxGetData(var), mmDims, NULL, depth); break;
             case mxINT16_CLASS:
                MLPutInteger16Array(link, (short *) mxGetData(var), mmDims, NULL, depth); break;
             case mxINT32_CLASS:
                MLPutInteger32Array(link, (int *) mxGetData(var), mmDims, NULL, depth); break;
             default:
                assert(false); // should never reach here
            }

            MLPutInteger32List(link, mmDims, depth);
        }
    }
    // logical (sparse or dense)
    else if (mxIsLogical(var))
        if (mxIsSparse(var)) {
            int ncols = mxGetN(var); // number of columns

            mwIndex *jc = mxGetJc(var);
            mwIndex *ir = mxGetIr(var);
            mxLogical *logicals = mxGetLogicals(var);

            int nnz = jc[ncols]; // number of nonzeros

            MLPutFunction(link, CONTEXT "matSparseLogical", 4);
            mlpPutIntegerList(link, jc, ncols + 1);
            mlpPutIntegerList(link, ir, nnz);

            short *integers = new short[nnz];
            std::copy(logicals, logicals+nnz, integers);

            MLPutInteger16List(link, integers, nnz);

            MLPutInteger32List(link, mmDims, depth);

            delete [] integers;
        }
        else // not sparse
        {
            mxLogical *logicals = mxGetLogicals(var);
            int len = mxGetNumberOfElements(var);

            short *integers = new short[len];
            std::copy(logicals, logicals+len, integers);

            MLPutFunction(link, CONTEXT "matLogical", 2);
            MLPutInteger16Array(link, integers, mmDims, NULL, depth);
            MLPutInteger32List(link, mmDims, depth);

            delete [] integers;
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
        putUnknown(var, link);
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

