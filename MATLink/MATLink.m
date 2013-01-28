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

InstallMATLAB::usage = "Establish connection with the MATLAB engine"
UninstallMATLAB::usage = "Close connection with the MATLAB engine"
OpenMATLAB::usage = "Open MATLAB workspace"
CloseMATLAB::usage = "Close MATLAB workspace"

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

(* Directories and helper functions/variables *)
$MATLABInstalledQ[] = False;
$mEngineBinaryExistsQ[] := FileExistsQ@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine"}];
$openLink = {};

(* Install/Uninstall MATLAB engine *)
InstallMATLAB::conn = "Already connected to MATLAB engine"
InstallMATLAB[] /; $mEngineBinaryExistsQ[] && !$MATLABInstalledQ[] :=
	Module[{},
		$openLink = Install@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine.sh"}];
		$MATLABInstalledQ[] = True;
	]
InstallMATLAB[] /; $mEngineBinaryExistsQ[] && $MATLABInstalledQ[] := Message[InstallMATLAB::conn]
InstallMATLAB[] /; !$mEngineBinaryExistsQ[] :=
	Module[{},
		CompileMEngine[];
		InstallMATLAB[];
	]

UninstallMATLAB::conn = "Not connected to MATLAB engine"
UninstallMATLAB[] /; $MATLABInstalledQ[] :=
	Module[{},
		LinkClose@$openLink;
		$openLink = {};
		$MATLABInstalledQ[] = False;
	]
UninstallMATLAB[] /; !$MATLABInstalledQ[] := Message[UninstallMATLAB::conn]

(* Open/Close MATLAB Workspace *)
OpenMATLAB::wksp = "MATLAB workspace is open";
OpenMATLAB[] /; $MATLABInstalledQ[] := openEngine[] /; !engineOpenQ[];
OpenMATLAB[] /; $MATLABInstalledQ[] := Message[OpenMATLAB::wksp] /; engineOpenQ[];
OpenMATLAB[] /; !$MATLABInstalledQ[] :=
	Module[{},
		InstallMATLAB[];
		OpenMATLAB[];
	]

CloseMATLAB::wksp = "MATLAB workspace is closed";
CloseMATLAB::conn = "Not connected to MATLAB engine";
CloseMATLAB[] /; $MATLABInstalledQ[] := closeEngine[] /; engineOpenQ[] ;
CloseMATLAB[] /; $MATLABInstalledQ[] := Message[CloseMATLAB::wksp] /; !engineOpenQ[];
CloseMATLAB[] /; !$MATLABInstalledQ[] := Message[CloseMATLAB::conn];

End[]

EndPackage[]
