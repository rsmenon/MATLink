/* 
 * To launch this program from within Mathematica use:
 *   In[1]:= link = Install["mEngine"]
 *
 * Or, launch this program from a shell and establish a
 * peer-to-peer connection.  When given the prompt Create Link:
 * type a port name. (On Unix platforms, a port name is a
 * number less than 65536.  On Mac or Windows platforms,
 * it's an arbitrary word.)
 * Then, from within Mathematica use:
 *   In[1]:= link = Install["portname", LinkMode->Connect]
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

	hinstPrevious = hinstPrevious; /* suppress warning */

	if( !MLInitializeIcon( hinstCurrent, nCmdShow)) return 1;
	MLScanString( argv, &argv_end, &lpszCmdLine, &buff_start);
	ml_main = MLMain( argv_end - argv, argv);

	if(NULL != Eng)
	{
		engClose(Eng);
		Eng = NULL;
	}

	return ml_main;
}

#else

int main(int argc, char* argv[])
{
	int result;

	result = MLMain(argc, argv);

	if(NULL != Eng)
	{
		engClose(Eng);
		Eng = NULL;
	}

	return result;
}

#endif
