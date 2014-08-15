/* set.cpp -- transfer data from Mathematica to MATLAB
 *
 * Copyright (c) 2014 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
 */

#include "mengine.h"

#include <vector>
#include <map>
#include <algorithm>
#include <cassert>


/* All eng_make_* functions create a handle to an mxArray data structure
 * The handles are represented as handle[integer] in Mathematica
 * The handles can be used in eng_set() to send the mxArray to MATLAB
 * as a variable, or in eng_make_Cell() and eng_make_Struct() to
 * populate their elements.
 */


// maps integers to mxArray *
// the integers are used handle[integer] expressions in Mathematica
class MatlabHandleSet {
    typedef std::map<int, mxArray *> mbmap;
    int counter;
    mbmap data;

public:
    MatlabHandleSet() : counter(0) { }
    ~MatlabHandleSet()  { clean(); }

    int add(mxArray *var) { data[counter] = var; return counter++; }
    void remove(int key) { data.erase(key); }
    mxArray *value(int key) { assert(data.find(key) != data.end()); return data[key]; }
    void clean() {
        for (mbmap::iterator i = data.begin(); i != data.end(); ++i)
            mxDestroyArray(i->second);
        data.clear();
    }

    friend void eng_get_handles();
};

static MatlabHandleSet handles;


// record handle and return it to Mathematica
void returnHandle(mxArray *var) {
    int handle = handles.add(var);
    MLPutFunction(stdlink, CONTEXT "handle", 1);
    MLPutInteger32(stdlink, handle);
}


// remove all handles
void eng_clean_handles() {
    handles.clean();
    MLPutSymbol(stdlink, "Null");
}


// return list of live handles to Mathematica
// used for debugging
void eng_get_handles() {
    MLPutFunction(stdlink, "List", handles.data.size());
    for (MatlabHandleSet::mbmap::iterator i = handles.data.begin(); i != handles.data.end(); ++i)
        MLPutInteger(stdlink, i->first);
}


void eng_make_RealArray(double *list, int len, int *mmDims, int depth) {
    std::vector<mwSize> mbDimsVec(depth);
    std::reverse_copy(mmDims, mmDims+depth, mbDimsVec.begin());
    mwSize *mbDims = &mbDimsVec[0];

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxREAL);
    std::copy(list, list+len, mxGetPr(var));

    returnHandle(var);
}


void eng_make_ComplexArray(double *real, int rlen, double *imag, int ilen, int *mmDims, int depth) {
    assert(ilen == rlen);

    std::vector<mwSize> mbDimsVec(depth);
    std::reverse_copy(mmDims, mmDims+depth, mbDimsVec.begin());
    mwSize *mbDims = &mbDimsVec[0];

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxCOMPLEX);
    std::copy(real, real+rlen, mxGetPr(var));
    std::copy(imag, imag+ilen, mxGetPi(var));

    returnHandle(var);
}


void eng_make_SparseReal(int *ir, int irlen, int *jc, int jclen, double *list, int len, int m, int n) {
    mxArray *var = mxCreateSparse(m, n, len, mxREAL);
    std::copy(ir, ir + irlen, mxGetIr(var));
    std::copy(jc, jc + jclen, mxGetJc(var));
    std::copy(list, list+len, mxGetPr(var));
    returnHandle(var);
}


void eng_make_SparseComplex(int *ir, int irlen, int *jc, int jclen, double *real, int rlen, double *imag, int ilen, int m, int n) {
    assert(rlen == ilen);
    mxArray *var = mxCreateSparse(m, n, rlen, mxCOMPLEX);
    std::copy(ir, ir + irlen, mxGetIr(var));
    std::copy(jc, jc + jclen, mxGetJc(var));
    std::copy(real, real+rlen, mxGetPr(var));
    std::copy(imag, imag+ilen, mxGetPi(var));
    returnHandle(var);
}



void eng_make_Logical(short *list, int len, int *mmDims, int depth) {
    std::vector<mwSize> mbDimsVec(depth);
    std::reverse_copy(mmDims, mmDims+depth, mbDimsVec.begin());
    mwSize *mbDims = &mbDimsVec[0];

    mxArray *var = mxCreateLogicalArray(depth, mbDims);
    std::copy(list, list+len, mxGetLogicals(var));
    returnHandle(var);
}


void eng_make_SparseLogical(int *ir, int irlen, int *jc, int jclen, short *list, int len, int m, int n) {
    mxArray *var = mxCreateSparseLogicalMatrix(m, n, len);
    std::copy(ir, ir + irlen, mxGetIr(var));
    std::copy(jc, jc + jclen, mxGetJc(var));
    std::copy(list, list+len, mxGetLogicals(var));
    returnHandle(var);
}


void eng_make_Cell(int *elems, int len, int *mmDims, int depth) {
    std::vector<mwSize> mbDimsVec(depth);
    std::reverse_copy(mmDims, mmDims+depth, mbDimsVec.begin());
    mwSize *mbDims = &mbDimsVec[0];

    mxArray *var = mxCreateCellArray(depth, mbDims);
    for (int i=0; i < len; ++i) {
        mxArray *el = handles.value(elems[i]);
        handles.remove(elems[i]); // remove to avoid double mxFree()
        mxSetCell(var, i, el);
    }

    returnHandle(var);
}


// note: as of Mathematica 10 and MATLAB R2014b, both only support UCS2, but not general UTF16 (surrogate pairs)
void eng_make_String(const unsigned short *str, int len) {
    mwSize mbDims[2] = {1, len};
    mxArray *var = mxCreateCharArray(2, mbDims);
    std::copy(str, str+len, (unsigned short *) mxGetChars(var));
    returnHandle(var);
}


void eng_make_Struct() {
    const char *name;
    int field_count;
    MLGetFunction(stdlink, &name, &field_count);

    std::vector<const char *> field_names(field_count);
    for (int i=0; i < field_count; ++i) {
        MLGetString(stdlink, &(field_names[i]));
    }

    int *handle_list;
    int handle_count;
    MLGetInteger32List(stdlink, &handle_list, &handle_count);

    int *mmDims;
    int depth;
    MLGetInteger32List(stdlink, &mmDims, &depth);

    std::vector<mwSize> mbDimsVec(depth);
    std::reverse_copy(mmDims, mmDims+depth, mbDimsVec.begin());
    mwSize *mbDims = &mbDimsVec[0];

    mxArray *var = mxCreateStructArray(depth, mbDims, field_count, &(field_names[0]));

    int len = handle_count / field_count;
    assert(mxGetNumberOfElements(var) == len);
    for (int i=0; i < len; ++i)
        for (int j=0; j < field_count; ++j) {
            mxSetFieldByNumber(var, i, j, handles.value(handle_list[i*len + j]));
            handles.remove(handle_list[i*len + j]); // remove to avoid double mxFree()
        }

    for (int i=0; i < field_count; ++i)
        MLReleaseString(stdlink, field_names[i]);

    MLReleaseInteger32List(stdlink, handle_list, handle_count);
    MLReleaseInteger32List(stdlink, mmDims, depth);

    returnHandle(var);
}


void eng_set(const char *name, int handle) {
    bool res = engine.putVariable(name, handles.value(handle));
    mxDestroyArray(handles.value(handle));
    handles.remove(handle);

    if (res)
        MLPutSymbol(stdlink, "Null");
    else
        MLPutSymbol(stdlink, "$Failed");
}
