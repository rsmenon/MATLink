/* main.cpp
 *
 * Copyright (c) 2013 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
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

