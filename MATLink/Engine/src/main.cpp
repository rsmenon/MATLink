/* main.cpp
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

#if WINDOWS_MATHLINK

#if __BORLANDC__
#pragma argsused
#endif

int PASCAL WinMain( HINSTANCE hinstCurrent, HINSTANCE hinstPrevious, LPSTR lpszCmdLine, int nCmdShow)
{
    char buff[512];
    char FAR * buff_start = buff;
    char FAR * argv[32];
    char FAR * FAR * argv_end = argv + 32;

    int ml_main;

    hinstPrevious = hinstPrevious; // suppress warning

    if( !MLInitializeIcon( hinstCurrent, nCmdShow)) return 1;
    MLScanString( argv, &argv_end, &lpszCmdLine, &buff_start);
    ml_main = MLMain( argv_end - argv, argv);

    return ml_main;
}

#else

int main(int argc, char* argv[])
{
    return MLMain(argc, argv);
}

#endif

