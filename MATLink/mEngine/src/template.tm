/****************************************************
 *
 * mEngine
 * Revision 2003.3.23
 * Robert (zhangchenhui99@mails.tsinghua.edu.cn)
 *
 * mEngine is a collection of wrappers to the MATLAB Engine 
 * Library for call from Mathematica.
 *
*******************************************************/

:Evaluate:
	BeginPackage["mEngine`"]

:Evaluate:
	eng::arg = 
	"Eng function argument error."

:Evaluate:
	eng::stMLB = 
	"Starting MATLAB..."

:Evaluate:
	eng::erMLB = 
	"Error starting MATLAB."

:Evaluate:
	eng::noMLB = 
	"MATLAB not opened."

:Evaluate:
	eng::aoMLB = 
	"MATLAB already opened."

:Evaluate:
	engOpen::usage = 
	"engOpen[] opens the MATLAB engine. It is a wrapper to the MATLAB Engine Interface engOpen."

:Evaluate:
	engClose::usage = 
	"engClose[] closes the MATLAB engine. It is a wrapper to the MATLAB Engine Interface engClose."

:Evaluate:
	engIsOpen::usage = 
	"engIsOpen[] gives True if the MATLAB Engine is opened, and False otherwise."


:Evaluate:
	engVis::usage = 
	"engVis[1] and engVis[0] shows or hides the MATLAB command window, respectively. It is a wrapper to the MATLAB Engine Interface engSetVisible."

:Evaluate:
	engVis::erchg = 
	"Error changing MATLAB visibility."

:Evaluate:
	engCmd::usage = 
	"engCmd[\"command\"] sends \"command\" to MATLAB. It is a wrapper to the the MATLAB Engine Interface engEvalString."

:Evaluate:
	engCmd::erexe = 
	"Error executing MATLAB command."

:Evaluate:
	engPut::usage = 
	"engPut[\"x\", dim, val] puts real list val, with MATLAB dimension dim, into the MATLAB workspace, and name it x. engPut[\"x\", dim, re, im] puts complex list whose real andimaginary parts are stored in re and im, with MATLAB dimension dim, into the MATLAB workspace, and name it x. It is a wrapper to the MATLAB Engine Interface engPutVariable."

:Evaluate:
	engPut::ercrt =	
	"Error creating MATLAB array."

:Evaluate:
	engPut::erput =	
	"Error putting array to the MATLAB workspace."

:Evaluate:
	engGet::usage = 
	"engGet[\"x\"] returns the variable x in the MATLAB workspace. It is a wrapper to the the MATLAB Engine Interface engGetVariable."

:Evaluate:
	engGet::erget =	
	"Error getting array from the MATLAB workspace. Array may not exist."

:Evaluate:
	engGet::ertp = 
	"Cannot get MATLAB array other than double precision numeric."

:Evaluate:
	EndPackage[]

/***************************************************************/

:Evaluate:  Begin["mEngine`Private`"]

:Begin:			
:Function:		engopen
:Pattern:		engOpen[___]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:

:Begin:			
:Function:		engclose
:Pattern:		engClose[___]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:

:Begin:			
:Function:		engisopen
:Pattern:		engIsOpen[___]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		engvis
:Pattern:		engVis[v:1|0]
:Arguments:		{v}
:ArgumentTypes:	{Integer}
:ReturnType:	Manual
:End:
:Evaluate:
	engVis[___] := Message[eng::arg]


:Begin:
:Function:		engcmd
:Pattern:		engCmd[cmd_String]

:Arguments:		{cmd}
:ArgumentTypes:	{UTF8String}
:ReturnType:	Manual
:End:
:Evaluate:
	engCmd[___] := Message[eng::arg]


:Begin:
:Function:		engputr
:Pattern:		engPut[nm_String, dim_, val_]/;
				VectorQ[dim, ToString[Head[#]] == "Integer" &] &&
				VectorQ[val, ToString[Head[#]] == "Real" &] &&
				Times@@dim == Length[val]

:Arguments:		{nm, dim, val}
:ArgumentTypes:	{String, IntegerList, RealList}
:ReturnType:	Manual
:End:

:Begin:
:Function:		engputc
:Pattern:		engPut[nm_String, dim_, re_, im_]/;
				VectorQ[dim, ToString[Head[#]] == "Integer" &] &&
				VectorQ[re, ToString[Head[#]] == "Real" &] &&
				VectorQ[im, ToString[Head[#]] == "Real" &] &&
				Times@@dim == Length[re] == Length[im]

:Arguments:		{nm, dim, re, im}
:ArgumentTypes:	{String, IntegerList, RealList, RealList}
:ReturnType:	Manual
:End:
:Evaluate:
	engPut[___] := Message[eng::arg]


:Begin:
:Function:		engget
:Pattern:		engGet[nm_String]

:Arguments:		{nm}
:ArgumentTypes:	{String}
:ReturnType:	Manual
:End:
:Evaluate:
	engGet[___] := Message[eng::arg]

/****************************************************************/

:Evaluate:  End[ ]

