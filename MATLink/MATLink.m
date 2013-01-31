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
MGet::usage = "Import MATLAB variable into Mathematica."
MSet::usage = "Define variable in MATLAB workspace."
MEvaluate::usage = "Evaluates a valid MATLAB expression"
MScript::usage = "Create a MATLAB script file"
MFunction::usage = "Create a link to a MATLAB function for use from Mathematica."
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

CleanupTemporaryDirectories[] :=
	DeleteDirectory[#, DeleteContents -> True] & /@ FileNames@FileNameJoin[{$TemporaryDirectory,"MATLink*"}];

SupportedMATLABTypeQ[expr_] :=
	Or[
		VectorQ[expr, NumericQ], (* 1D lists/row vectors *)
		MatrixQ[expr, NumericQ] (* Matrices *)
	]

End[]

(* Low level functions strongly tied with the C code
	are part of this context *)
Begin["`mEngine`"]

engGet::unimpl = "Translating the MATAB type \"`1`\" is not supported"

(* The following mat* functions translate the semi-raw MATLAB data returned
   by mEngine into their final Mathematica form.  engGet[] will always return
   either $Failed, or an expression wrapped in one of the below heads.
   Note that structs and cells may contain subxpressions of other types.
*)

matUnknown[s_] := (Message[engGet::unimpl, s]; $Failed)

standardize[arr_, {1, 1}]  := arr[[1,1 ]] 
standardize[arr_, {_, 1}] := arr[[All, 1]]
standardize[arr_, dims_] := Transpose[arr, PermutationList@Cycles[{Length[dims] - {1,0}}]]

matArray[arr_, dims_] := standardize[arr, dims]

matCell[lst_, dims_] := standardize[First@Fold[Partition, lst, Reverse[dims]], dims]

matString[s_] := s

matStruct[s_] := s (* TODO implement multielement structs *)

End[]


Begin["`Private`"]
AppendTo[$ContextPath, "MATLink`Developer`"];
AppendTo[$ContextPath, "MATLink`mEngine`"];

(* Lowlevel mEngine functions *)
engineOpenQ = MATLink`mEngine`engIsOpen;
openEngine = MATLink`mEngine`engOpen;
closeEngine = MATLink`mEngine`engClose;
cmd = MATLink`mEngine`engCmd;
get = MATLink`mEngine`engGet;
set = MATLink`mEngine`engSet;

(* Directories and helper functions/variables *)
MATLABInstalledQ[] = False;
mEngineBinaryExistsQ[] := FileExistsQ@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine"}];
$openLink = {};
$sessionID = "";
$temporaryVariablePrefix = "";
$sessionTemporaryDirectory = "";

mEngineLinkQ[LinkObject[link_String, _, _]] := ! StringFreeQ[link, "mEngine.sh"];

cleanupOldLinks[] :=
	Module[{},
		LinkClose /@ Select[Links[], mEngineLinkQ];
		MATLABInstalledQ[] = False;
	]

MScriptQ[name_String] /; MATLABInstalledQ[] :=
	FileExistsQ[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]]

convertToMathematica[expr_] :=
	Which[
		ArrayQ[expr, _, NumericQ], Transpose[
			expr, Range@ArrayDepth@expr /. {i_, j_, k___} :> Reverse@{k}~Join~{i, j}],
		StringQ, expr,
		True, expr
	]

convertToMATLAB[expr_] :=
	Which[
		ArrayQ[expr, _, NumericQ], Transpose[
			expr, Range@ArrayDepth@expr /. {k___, i_, j_} :> {i, j}~Join~Reverse@{k}],
		True, expr
	]

(* Common error messages *)
General::wspo = "The MATLAB workspace is already open."
General::wspc = "The MATLAB workspace is already closed."
General::engo = "There is an existing connection to the MATLAB engine."
General::engc = "Not connected to the MATLAB engine."
General::nofn = "The `1` \"`2`\" does not exist."
General::owrt = "An `1` by that name already exists. Use OverWrite \[Rule] True to overwrite."

(* Connect/Disconnect MATLAB engine *)
ConnectMATLAB[] /; mEngineBinaryExistsQ[] && !MATLABInstalledQ[] :=
	Module[{},
		cleanupOldLinks[];
		$openLink = Install@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine.sh"}];
		$sessionID = StringJoin[
			 IntegerString[{Most@DateList[]}, 10, 2],
			 IntegerString[List @@ Rest@$openLink]
		];
		$temporaryVariablePrefix = "MATLink" <> $sessionID;
		$sessionTemporaryDirectory = FileNameJoin[{$TemporaryDirectory, "MATLink" <> $sessionID}];
		CreateDirectory@$sessionTemporaryDirectory;
		MATLABInstalledQ[] = True;
	]
ConnectMATLAB[] /; mEngineBinaryExistsQ[] && MATLABInstalledQ[] := Message[ConnectMATLAB::engo]
ConnectMATLAB[] /; !mEngineBinaryExistsQ[] :=
	Module[{},
		CompileMEngine[];
		ConnectMATLAB[];
	]

DisconnectMATLAB[] /; MATLABInstalledQ[] :=
	Module[{},
		LinkClose@$openLink;
		$openLink = {};
		DeleteDirectory[$sessionTemporaryDirectory, DeleteContents -> True];
		MATLABInstalledQ[] = False;
	]
DisconnectMATLAB[] /; !MATLABInstalledQ[] := Message[DisconnectMATLAB::engc]

(* Open/Close MATLAB Workspace *)
OpenMATLAB[] /; MATLABInstalledQ[] := openEngine[] /; !engineOpenQ[];
OpenMATLAB[] /; MATLABInstalledQ[] := Message[OpenMATLAB::wspo] /; engineOpenQ[];
OpenMATLAB[] /; !MATLABInstalledQ[] :=
	Module[{},
		ConnectMATLAB[];
		OpenMATLAB[];
		MEvaluate["addpath('" <> $sessionTemporaryDirectory <> "')"];
	]

CloseMATLAB[] /; MATLABInstalledQ[] := closeEngine[] /; engineOpenQ[] ;
CloseMATLAB[] /; MATLABInstalledQ[] := Message[CloseMATLAB::wspc] /; !engineOpenQ[];
CloseMATLAB[] /; !MATLABInstalledQ[] := Message[CloseMATLAB::engc];

(*  High-level commands *)
SyntaxInformation[MGet] = {"ArgumentsPattern" -> {_}};
MGet[var_String] /; MATLABInstalledQ[] :=
	convertToMathematica@get[var] /; engineOpenQ[]
MGet[_String] /; MATLABInstalledQ[] := Message[MGet::wspc] /; !engineOpenQ[]
MGet[_String] /; !MATLABInstalledQ[] := Message[MGet::engc]

SyntaxInformation[MSet] = {"ArgumentsPattern" -> {_, _}};
MSet[var_String, expr_] /; MATLABInstalledQ[] :=
	set[var, convertToMATLAB@expr] /; engineOpenQ[]
MSet[___] /; MATLABInstalledQ[] := Message[MSet::wspc] /; !engineOpenQ[]
MSet[___] /; !MATLABInstalledQ[] := Message[MSet::engc]

SyntaxInformation[MEvaluate] = {"ArgumentsPattern" -> {_}};
MEvaluate[cmd_String] /; MATLABInstalledQ[] := engCmd[cmd] /; engineOpenQ[]
MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && MScriptQ[name] :=
	engCmd[name] /; engineOpenQ[]
MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && !MScriptQ[name] :=
	Message[MEvaluate::nofn,"MScript", name]
MEvaluate[___] /; MATLABInstalledQ[] := Message[MEvaluate::wspc] /; !engineOpenQ[]
MEvaluate[___] /; !MATLABInstalledQ[] := Message[MEvaluate::engc]

Options[MScript] = {OverWrite -> False};
MScript[name_String, cmd_String, OptionsPattern[]] /; MATLABInstalledQ[] :=
	Module[{file},
		file = OpenWrite[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]];
		WriteString[file, cmd];
		Close[file];
	] /; (!MScriptQ[name] || OptionValue[OverWrite])
MScript[name_String, cmd_String, OptionsPattern[]] /; MATLABInstalledQ[] :=
	Message[MScript::owrt, "MScript"] /; MScriptQ[name] && !OptionValue[OverWrite]
MScript[name_String, cmd_String, OptionsPattern[]] /; !MATLABInstalledQ[] := Message[MScript::engc]

MFunction[name_String][args___] /; MATLABInstalledQ[] :=
	With[{vars = Table[ToString@Unique[$temporaryVariablePrefix], {Length[{args}]}]},
		Thread[MSet[vars, {args}]];
		MEvaluate[StringJoin[name, "(", Riffle[vars, ","], ")"]];
		MEvaluate[StringJoin["clear ", Riffle[vars, " "]]];
	]
MFunction[name_String][args___] /; MATLABInstalledQ[] := Message[MFunction::wspc] /; !engineOpenQ[]
MFunction[name_String][args___] /; !MATLABInstalledQ[] := Message[MFunction::engc]

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
