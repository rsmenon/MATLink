
#include "mengine.h"

#include <algorithm>
#include <cstring>

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
    MLPutUTF8String(stdlink, (const unsigned char*) engine.getBuffer(), strlen(engine.getBuffer()));
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
