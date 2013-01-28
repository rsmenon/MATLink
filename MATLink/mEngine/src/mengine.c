/*
 * mengine.c
 *
 *	
 */


#include "mengine.h"

#include <string.h>


Engine *Eng = NULL;


void msg(const char* m) {
	char cmd[100] = "Message[";
	strcat(strcat(cmd, m), "]");
	MLEvaluateString(stdlink, cmd);
}
