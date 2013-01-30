(* :Title: MATLink *)
(* :Context: MATLink` *)
(* :Authors:
	R. Menon (rsmenon@icloud.com)
	Sz. Horvát (szhorvat@gmail.com)
*)
(* :Package Version: 0.1 *)
(* :Mathematica Version: 9.0 *)

BeginPackage["MATLink`"]
ClearAll@"`*`*"

ConnectMATLAB::usage = "Establish connection with the MATLAB engine"
DisconnectMATLAB::usage = "Close connection with the MATLAB engine"
OpenMATLAB::usage = "Open MATLAB workspace"
CloseMATLAB::usage = "Close MATLAB workspace"
MEvaluate::usage = "Evaluates a valid MATLAB expression"
MCell::usage = "Creates a MATLAB cell"

Begin["`Developer`"]
$mEngineSourceDirectory = FileNameJoin[{DirectoryName@$InputFileName, "mEngine","src"}];
$defaultMATLABDirectory = "/Applications/MATLAB_R2012b.app/";

CompileMEngine[] :=
	Block[{dir = Directory[]},
		SetDirectory[$mEngineSourceDirectory];
		PrintTemporary["Compiling mEngine from source...\n"];
		Run["make"];
		DeleteFile@FileNames@"*.o";
		Run["mv mEngine ../"];
		SetDirectory@dir
	]
End[]

SupportedMATLABTypeQ[expr_] :=
	Or[
		VectorQ[expr, NumericQ], (* 1D lists/row vectors *)
		MatrixQ[expr, NumericQ] (* Matrices *)
	]

Begin["`Private`"]
AppendTo[$ContextPath, "MATLink`Developer`"];
AppendTo[$ContextPath, "mEngine`"];

(* Lowlevel mEngine functions *)
engineOpenQ = mEngine`engIsOpen;
openEngine = mEngine`engOpen;
closeEngine = mEngine`engClose;
cmd = mEngine`engCmd;

(* Directories and helper functions/variables *)
MATLABInstalledQ[] = False;
mEngineBinaryExistsQ[] := FileExistsQ@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine"}];
$openLink = {};
$sessionID = {};
$sessionTemporaryDirectory = {};

mEngineLinkQ[LinkObject[link_String, _, _]] := ! StringFreeQ[link, "mEngine.sh"];
cleanupOldLinks[] :=
	Module[{},
		LinkClose /@ Select[Links[], mEngineLinkQ];
		MATLABInstalledQ[] = False;
	]

(* Connect/Disconnect MATLAB engine *)
ConnectMATLAB::conn = "Already connected to MATLAB engine"
ConnectMATLAB[] /; mEngineBinaryExistsQ[] && !MATLABInstalledQ[] :=
	Module[{},
		cleanupOldLinks[];
		$openLink = Install@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine.sh"}];
		$sessionID = StringJoin[
			 IntegerString[{Most@DateList[]}, 10, 2],
			 IntegerString[List @@ Rest@$openLink]
		];
		$sessionTemporaryDirectory = FileNameJoin[{$TemporaryDirectory, "MATLink" <> $sessionID}];
		MATLABInstalledQ[] = True;
	]
ConnectMATLAB[] /; mEngineBinaryExistsQ[] && MATLABInstalledQ[] := Message[ConnectMATLAB::conn]
ConnectMATLAB[] /; !mEngineBinaryExistsQ[] :=
	Module[{},
		CompileMEngine[];
		ConnectMATLAB[];
	]

DisconnectMATLAB::conn = "Not connected to MATLAB engine"
DisconnectMATLAB[] /; MATLABInstalledQ[] :=
	Module[{},
		LinkClose@$openLink;
		$openLink = {};
		MATLABInstalledQ[] = False;
	]
DisconnectMATLAB[] /; !MATLABInstalledQ[] := Message[DisconnectMATLAB::conn]

(* Open/Close MATLAB Workspace *)
OpenMATLAB::wksp = "MATLAB workspace is open";
OpenMATLAB[] /; MATLABInstalledQ[] := openEngine[] /; !engineOpenQ[];
OpenMATLAB[] /; MATLABInstalledQ[] := Message[OpenMATLAB::wksp] /; engineOpenQ[];
OpenMATLAB[] /; !MATLABInstalledQ[] :=
	Module[{},
		ConnectMATLAB[];
		OpenMATLAB[];
	]

CloseMATLAB::wksp = "MATLAB workspace is closed";
CloseMATLAB::conn = "Not connected to MATLAB engine";
CloseMATLAB[] /; MATLABInstalledQ[] := closeEngine[] /; engineOpenQ[] ;
CloseMATLAB[] /; MATLABInstalledQ[] := Message[CloseMATLAB::wksp] /; !engineOpenQ[];
CloseMATLAB[] /; !MATLABInstalledQ[] := Message[CloseMATLAB::conn];

(*  High-level commands *)
MEvaluate::wksp = "MATLAB workspace is closed. Open a session using OpenMATLAB[] first before evaluating.";
MEvaluate::conn = "Not connected to MATLAB engine. Create a connection using ConnectMATLAB[].";

SyntaxInformation[MEvaluate] = {"ArgumentsPattern" -> {_}};

MEvaluate[cmd_String] /; MATLABInstalledQ[] := engCmd[cmd] /; engineOpenQ[]
MEvaluate[cmd_String] /; MATLABInstalledQ[] := Message[MEvaluate::wksp] /; !engineOpenQ[]
MEvaluate[cmd_String] /; !MATLABInstalledQ[] := Message[MEvaluate::conn]

MCell[] :=
	Module[{},
		CellPrint@Cell[
			TextData[""],
			"Program",
			Evaluatable->True,
			CellEvaluationFunction -> (MEvaluate[ToString@#]&),
			CellFrameLabels -> {{None,"MATLAB"},{None,None}}
		];
		SelectionMove[EvaluationNotebook[], All, EvaluationCell];
		NotebookDelete[];
		SelectionMove[EvaluationNotebook[], Next, CellContents]
	]

End[]

EndPackage[]
