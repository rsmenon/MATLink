/* mengine.cpp
 *
 * Copyright 2013 Sz. Horvát and R. Menon
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


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


void eng_set_visible(int value) {
    engine.setVisible(value);
    MLPutSymbol(stdlink, "Null");
}
