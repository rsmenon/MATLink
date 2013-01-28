/*
 * cmd.c
 *
 * Wrapper of the MatLab Engine API engEvalString
 * for call from Mathematica
 *
 * Revision 2003.3.11
 *
 * Robert
 *	
 */

#include "mengine.h"

#include <string.h>

#define  BUFSIZE (100*1024)	// 100k for output buffer


void engcmd(const char* command, int bytes, int characters)
{
	char buffer[BUFSIZE+1];		// MATLAB output buffer
	char szcommand[bytes+1];	// null-terminated version of 'command'
	bool SUCCESS = true;		// success flag

    buffer[BUFSIZE] = '\0';	// ensure buffer is null-terminated even when full

    // make null-terminated version of 'command':
    memcpy(szcommand, command, bytes);
    szcommand[bytes] = '\0';

	if (NULL == Eng)	//if not opened yet
	{
		msg("eng::noMLB");	//message 
		SUCCESS = false;
	}
	else
	{
		engOutputBuffer(Eng, buffer, BUFSIZE);	//for return output
		//issue command
		if(engEvalString(Eng, szcommand))	//if unsucessful
		{
			msg("engCmd::erexe");
			SUCCESS = false;
		}
	}

	if(SUCCESS)
		MLPutUTF8String(stdlink, (unsigned char *) buffer, strlen(buffer));
	else
		MLPutSymbol(stdlink, "$Failed");

}
