/* mengine.cpp
 *
 * Copyright (c) 2013 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
 */

#include "mengine.h"

#include <algorithm>
#include <cstring>
#include <cassert>

MatlabEngine engine; // global variable for engine


void eng_open() {
    engine.open();
    MLPutSymbol(stdlink, "Null");
}


void eng_open_q() {
    if (engine.isopen())
        MLPutSymbol(stdlink, "True");
    else
        MLPutSymbol(stdlink, "False");
}


void eng_close() {
    engine.close();
    MLPutSymbol(stdlink, "Null");
}


void eng_getbuffer() {
    const char *buf = engine.getBuffer();
    char *escaped = new char[2*BUFSIZE+1];

    const char *in = buf;
    char *out = escaped;
    while (*in != '\0') {
        if (*in == '\\') {
            *out = '\\';
            *(out+1) = '\\';
            out += 2;
            in += 1;
        }
        else
            *(out++) = *(in++);
    }
    *out = *in; // copy final '\0'

    // temporarily disable sending engEvaluate[] output as unicode to avoid crashes
    // MLPutString needs all backslashes to be escaped.
    MLPutString(stdlink, escaped);
    //MLPutUTF8String(stdlink, (const unsigned char*) engine.getBuffer(), strlen(engine.getBuffer()));

    delete [] escaped;
}


void eng_evaluate(const unsigned char *command, int len, int characters) {
    char *szcommand = new char[len+1];
    std::copy(command, command+len, (unsigned char *) szcommand);
    szcommand[len] = '\0';
    if (engine.evaluate(szcommand))
        eng_getbuffer();
    else
        MLPutSymbol(stdlink, "$Failed");
    delete [] szcommand;
}

void eng_evaluate_with_trap(const unsigned short *command, int len, int characters) {
    mwSize mbDims[2] = {1, len}; // use len, not characters, because no support for 4-byte characters in either Mma 9 or MATLAB
    mxArray *cmd = mxCreateCharArray(2, mbDims);
    std::copy(command, command+len, (unsigned short *) mxGetChars(cmd));
    mxArray *res;
    mxArray *err;
    err = mexCallMATLABWithTrap(1, &res, 1, &cmd, "evalc");
    
    MLPutFunction(stdlink, "List", 2);
    if (err == NULL) {
        MLPutSymbol(stdlink, "Null");

        assert(mxIsChar(res));
        int len = mxGetNumberOfElements(res);
        const mxChar *str = mxGetChars(res);
        MLPutUTF16String(stdlink, reinterpret_cast<const unsigned short *>(str), len);
        mxDestroyArray(res);
    }
    else {        
        mxArray *msg;
        int errCode = mexCallMATLAB(1, &msg, 1, &err, "getReport"); // TODO check error
        assert(errCode == 0);
        assert(mxIsChar(msg));
        int len = mxGetNumberOfElements(msg);
        const mxChar *str = mxGetChars(msg);
        MLPutUTF16String(stdlink, reinterpret_cast<const unsigned short *>(str), len);
        mxDestroyArray(msg);
        mxDestroyArray(err);

        MLPutSymbol(stdlink, "$Failed");

        // check if res is NULL
    }
    mxDestroyArray(cmd);
}

void eng_set_visible(int value) {
    engine.setVisible(value);
    MLPutSymbol(stdlink, "Null");
}


#if !WINDOWS_MATHLINK
// this message handler will try to abort MATLAB when receiving an abort message
MLMDEFN(void, msghandler, (MLINK link, int msg, int arg)) {
    switch (msg) {
    case MLTerminateMessage:
        MLDone = 1;
        MLAbort = 1;
    case MLInterruptMessage:
    case MLAbortMessage:
        engine.abort();
        break;
    default:
        stdhandler(link, msg, arg);
    }
}

int setup_abort_handler() {
    return MLSetMessageHandler(stdlink, (MLMessageHandlerObject) msghandler);
}
#else
int setup_abort_handler() {
    return 0; // unsupported on Windows
}
#endif
