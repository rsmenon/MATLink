
#include "mengine.h"

#include <map>
#include <cstring>
#include <cassert>

class MatlabHandleSet {
    typedef std::map<int, mxArray *> mbmap;
    int counter;
    mbmap data;

public:
    MatlabHandleSet() : counter(0) { }
    ~MatlabHandleSet()  {
        for (mbmap::iterator i = data.begin(); i != data.end(); ++i)
            mxDestroyArray(i->second);
    }

    int add(mxArray *var) { data[counter] = var; return counter++; }
    void remove(int key) { data.erase(key); }
    mxArray *value(int key) { return data.at(key); }
};

static MatlabHandleSet handles;


void returnHandle(mxArray *var) {
    int handle = handles.add(var);
    MLPutFunction(stdlink, CONTEXT "handle", 1);
    MLPutInteger64(stdlink, handle);
}


void eng_make_RealArray(double *list, int len, int *mmDims, int depth) {
    mwSize mbDims[depth];
    for (int i=0; i < depth; ++i)
        mbDims[i] = mmDims[depth - i - 1];

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxREAL);
    memcpy(mxGetPr(var), list, len*sizeof(double));

    returnHandle(var);
}


void eng_make_ComplexArray(double *real, int rlen, double *imag, int ilen, int *mmDims, int depth) {
    assert(ilen == rlen);

    mwSize mbDims[depth];
    for (int i=0; i < depth; ++i)
        mbDims[i] = mmDims[depth - i - 1];

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxREAL);
    memcpy(mxGetPr(var), real, rlen*sizeof(double));
    memcpy(mxGetPi(var), imag, ilen*sizeof(double));

    returnHandle(var);
}


void eng_make_Cell(int *elems, int len, int *mmDims, int depth) {
    mwSize mbDims[depth];
    for (int i=0; i < depth; ++i)
        mbDims[i] = mmDims[depth - i - 1];

    mxArray *var = mxCreateCellArray(depth, mbDims);
    for (int i=0; i < len; ++i) {
        mxArray *el = handles.value(elems[i]);
        handles.remove(elems[i]);
        mxSetCell(var, i, el);
    }

    returnHandle(var);
}


void eng_make_String(const unsigned short *str, int len, int characters) {
    mwSize mbDims[2] = {1, len}; // use len, not characters, because no support for 4-byte characters in either Mma 9 or MATLAB
    mxArray *var = mxCreateCharArray(2, mbDims);
    memcpy(mxGetChars(var), str, len*sizeof(const unsigned short));
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
