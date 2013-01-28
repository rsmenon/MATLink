/*
 * vis.c
 *
 * Wrapper of the MatLab Engine API engSetVisible
 * for call from Mathematica
 *
 * Revision 2003.3.11
 *
 * Robert
 *	
 */

#include "mengine.h"


void engvis(int v)
{
	bool SUCCESS = true;		//success flag
	bool vs = !(0 == v);

	if (NULL == Eng)	//if MATLAB not opened
	{
		msg("eng::noMLB");	//message 
		SUCCESS = false;
	}
	else if(engSetVisible(Eng, vs))	//if error occurs
	{
		msg("engVis::erchg");	
		SUCCESS = false;
	}

	if(SUCCESS)
		MLPutSymbol(stdlink, "Null");
	else
		MLPutSymbol(stdlink, "$Failed");

}
