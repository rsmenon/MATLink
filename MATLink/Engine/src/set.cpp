
#include "mengine.h"

#include <map>
#include <algorithm>
#include <cassert>

class MatlabHandleSet {
    typedef std::map<int, mxArray *> mbmap;
    int counter;
    mbmap data;

public:
    MatlabHandleSet() : counter(0) { }
    ~MatlabHandleSet()  { clean(); }

    int add(mxArray *var) { data[counter] = var; return counter++; }
    void remove(int key) { data.erase(key); }
    mxArray *value(int key) { return data.at(key); }
    void clean() {
        for (mbmap::iterator i = data.begin(); i != data.end(); ++i)
            mxDestroyArray(i->second);
        data.clear();
    }

    friend void eng_get_handles();
};

static MatlabHandleSet handles;


void returnHandle(mxArray *var) {
    int handle = handles.add(var);
    MLPutFunction(stdlink, CONTEXT "handle", 1);
    MLPutInteger64(stdlink, handle);
}


void eng_clean_handles() {
    handles.clean();
    MLPutSymbol(stdlink, "Null");
}


void eng_get_handles() {
    MLPutFunction(stdlink, "List", handles.data.size());
    for (MatlabHandleSet::mbmap::iterator i = handles.data.begin(); i != handles.data.end(); ++i)
        MLPutInteger(stdlink, i->first);
}


void eng_make_RealArray(double *list, int len, int *mmDims, int depth) {
    mwSize mbDims[depth];
    std::reverse_copy(mmDims, mmDims+depth, mbDims);

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxREAL);
    std::copy(list, list+len, mxGetPr(var));

    returnHandle(var);
}


void eng_make_ComplexArray(double *real, int rlen, double *imag, int ilen, int *mmDims, int depth) {
    assert(ilen == rlen);

    mwSize mbDims[depth];
    std::reverse_copy(mmDims, mmDims+depth, mbDims);

    mxArray *var = mxCreateNumericArray(depth, mbDims, mxDOUBLE_CLASS, mxREAL);
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
    mwSize mbDims[depth];
    std::reverse_copy(mmDims, mmDims+depth, mbDims);

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
    mwSize mbDims[depth];
    std::reverse_copy(mmDims, mmDims+depth, mbDims);

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
    std::copy(str, str+len, (unsigned short *) mxGetChars(var));
    returnHandle(var);
}


void eng_make_Struct() {
    const char *name;
    int field_count;
    MLGetFunction(stdlink, &name, &field_count);

    const char *field_names[field_count]; // okay to allocate on stack, not many fields
    for (int i=0; i < field_count; ++i) {
        MLGetString(stdlink, &(field_names[i]));
    }
    mxArray *var = mxCreateStructMatrix(1, 1, field_count, &(field_names[0]));

    for (int i=0; i < field_count; ++i)
        MLReleaseString(stdlink, field_names[i]);

    int *handle_list;
    int handle_count;
    MLGetInteger32List(stdlink, &handle_list, &handle_count);
    assert(field_count == handle_count);
    for (int i=0; i < handle_count; ++i) {
        mxSetFieldByNumber(var, 0, i, handles.value(handle_list[i]));
        handles.remove(handle_list[i]);
    }

    MLReleaseInteger32List(stdlink, handle_list, handle_count);

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
