/* mengine.h
 *
 * Copyright (c) 2013 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
 */

#ifndef MENGINE_H
#define MENGINE_H

#include "mlp.h"

#include <engine.h>
#include <matrix.h>

#if !WINDOWS_MATHLINK
#include <signal.h>
#endif

// context of all symbols returned to Mathematica
#define CONTEXT "MATLink`Engine`"

// the maximum size for MATLAB output
#define BUFSIZE (100*1024)  // 100 kB


// preprocessor flags for various platforms
#if WINDOWS_MATHLINK  // from mathlink.h
#define ENGINE_WIN    // compiling on Windows
#endif


class MatlabVariable {
    mxArray *arr;

    MatlabVariable(const MatlabVariable &);   // disallowed
    void operator = (const MatlabVariable &); // disallowed
public:
    MatlabVariable(mxArray *var) : arr(var) { }
    ~MatlabVariable() { mxDestroyArray(arr); }
};

// Note:
// When running on OS X, lots of isopen() check are necessary to avoid crashes
// if MATLAB has quit.  This may not be necessary on Windows.
class MatlabEngine {
    Engine *ep;
    char buffer[BUFSIZE+1];

#if !WINDOWS_MATHLINK
    pid_t pid;
    bool pid_set;
#endif

    MatlabEngine(const MatlabEngine &);     // disallowed
    void operator = (const MatlabEngine &); // disallowed

public:
    MatlabEngine() : ep(NULL) {
        buffer[0] = '\0';       // zero-length on init
        buffer[BUFSIZE] = '\0'; // ensure buffer is always null-terminated
    }

    ~MatlabEngine() { close(); }

    bool isopen() {
        evaluate("");   // attempt evaluating something to detect if MATLAB has quit
        return (ep != NULL);
    }

    void open() {
        if (! isopen()) {
#ifdef ENGINE_WIN
            ep = engOpen(NULL);
#else
            ep = engOpen("matlab -nosplash");
#endif
            if (ep != NULL) {
                engSetVisible(ep, 0); // hide the window on Windows
                buffer[0] = '\0';
                engOutputBuffer(ep, buffer, BUFSIZE);

                // Mathematica will interpret MATLAB's output as UTF-8,
                // so let's try to get MATLAB to send this encoding.
                // Note: works in OSX 2012b and Linux 2013a.  Does work in OSX/Windows 2013a
                engEvalString(ep, "feature('DefaultCharacterSet', 'UTF-8');");

#if !WINDOWS_MATHLINK
                engEvalString(ep, "feature('GetPid');");
                mxArray *ans = engGetVariable(ep, "ans");
                if (ans != NULL && mxIsNumeric(ans)) {
                    pid = (pid_t) mxGetScalar(ans);
                    pid_set = true;
                    mxDestroyArray(ans);
                }
                else
                    pid_set = false;
#endif
                engEvalString(ep, "clear ans;");
            }
        }
        // if opening fails, ep stays NULL
        // use isopen() to test for success
    }

    void close() {
        if (isopen())
            engClose(ep);
        ep = NULL;
    }

    // returns true on success
    // warning: because of a MATLAB Engine bug
    // engEvalString() will hang on an incomplete expression such as "x = [1"
    bool evaluate(const char *command) {
        // contrary to the docs, engEvalString crashes when given a NULL pointer
        // so let's check here:
        if (ep == NULL)
            return false;

        int res = engEvalString(ep, command);
        if (res)    // failure
            ep = NULL;
        return !res;
    }

    const char *getBuffer() const {
        return buffer;
    }

    mxArray *getVariable(const char *name) {
        if (!isopen())  // avoid crash if MATLAB has quit
            return NULL;
        return engGetVariable(ep, name);
    }

    bool putVariable(const char *name, mxArray *var) {
        if (!isopen())  // avoid crash if MATLAB has quit
            return false;
        int res = engPutVariable(ep, name, var);
        return !res;
    }

    void setVisible(bool val) {
        if (!isopen())
            return;
        engSetVisible(ep, val);
    }

#if !WINDOWS_MATHLINK
    void abort() {
        if (pid_set)
            kill(pid, SIGINT);
    }
#endif
};


extern MatlabEngine engine;

#endif // MENGINE_H
