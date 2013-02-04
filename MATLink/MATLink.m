(* :Title: MATLink *)
(* :Context: MATLink` *)
(* :Authors:
	R. Menon (rsmenon@icloud.com)
	Sz. Horvát (szhorvat@gmail.com)
*)
(* :Package Version: 0.1 *)
(* :Mathematica Version: 9.0 *)

BeginPackage["MATLink`"]

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
$ReturnLogicalsAs0And1::usage = "If set to True, MATLAB logicals will be returned as 0 or 1, and True or False otherwise."
$OutputIsCell::usage = "Returns True if the last output was a MATLAB cell and False otherwise."

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

Begin["`Private`"]
AppendTo[$ContextPath, "MATLink`Developer`"];

(* Directories and helper functions/variables *)
$ApplicationDirectory = DirectoryName@$InputFileName;
mEngineBinaryExistsQ[] := FileExistsQ@FileNameJoin[{ParentDirectory@$mEngineSourceDirectory, "mEngine"}];

If[!TrueQ[MATLABInstalledQ[]],
	MATLABInstalledQ[] = False;
	$openLink = {};
	$sessionID = "";
	$temporaryVariablePrefix = "";
	$sessionTemporaryDirectory = "";,

	General::needs = "MATLink is already loaded. Remember to use Needs instead of Get.";
	Message[General::needs]
]

mEngineLinkQ[LinkObject[link_String, _, _]] := ! StringFreeQ[link, "mEngine.sh"];

cleanupOldLinks[] :=
	Module[{},
		LinkClose /@ Select[Links[], mEngineLinkQ];
		MATLABInstalledQ[] = False;
	]

MScriptQ[name_String] /; MATLABInstalledQ[] :=
	FileExistsQ[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]]

convertToMATLAB[expr_] :=
	Which[
		ArrayQ[expr, _, NumericQ], Transpose[
			expr, Range@ArrayDepth@expr /. {k___, i_, j_} :> {i, j}~Join~Reverse@{k}],
		True, expr
	]

randomFileName[] :=
	StringJoin@RandomSample[Join[#, ToLowerCase@#] &@CharacterRange["A", "Z"], 50]

mLintErrorCheck[cmd_String] :=
	Module[
		{
			file = MScript[randomFileName[], cmd],
			config = FileNameJoin[{$ApplicationDirectory, "Kernel","MLintErrors.txt"}],
			result
		},
		eval@ToString@StringForm[
			"`1` = checkcode('`2`','-id','-config=`3`')",
			First@file, file["AbsolutePath"],config
		];
		result = MGet@First@file;
		DeleteFile@file["AbsolutePath"];
		result
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
$ReturnLogicalsAs0And1 = False;
$OutputIsCell = False;

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
MEvaluate[cmd_String] /; MATLABInstalledQ[] :=
	Module[{file = MScript[randomFileName[],cmd]},
		(* Check if input contains syntax errors, as otherwise, the engine hangs *)
		eval[cmd]
	] /; engineOpenQ[]
MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && MScriptQ[name] :=
	eval[name] /; engineOpenQ[]
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
		MScript[name]
	] /; (!MScriptQ[name] || OptionValue[OverWrite])
MScript[name_String, cmd_String, OptionsPattern[]] /; MATLABInstalledQ[] :=
	Message[MScript::owrt, "MScript"] /; MScriptQ[name] && !OptionValue[OverWrite]
MScript[name_String, cmd_String, OptionsPattern[]] /; !MATLABInstalledQ[] := Message[MScript::engc]
MScript[name_String]["AbsolutePath"] /; MScriptQ[name] :=
	FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]

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

(* Low level functions strongly tied with the C code are part of this context *)
Begin["`mEngine`"]
AppendTo[$ContextPath, "MATLink`Private`"]

(* Assign to symbols defined in `Private` *)
engineOpenQ[] /; MATLABInstalledQ[] := engIsOpen[]
engineOpenQ[] /; !MATLABInstalledQ[] := (Message[engineOpenQ::engc];False)
openEngine = engOpen;
closeEngine = engClose;
eval = engCmd;
get = engGet;
set = engSet;

engGet::unimpl = "Translating the MATLAB type \"`1`\" is not supported"

(* The following mat* heads are inert and indicate the type of the MATLAB data returned
   by mEngine. Evaluation is only allowed inside the convertToMathematica
   function, which converts it to their final Mathematica form.  engGet[] will always return
   either $Failed, or an expression wrapped in one of the below heads.
   Note that structs and cells may contain subxpressions of other types.
*)

convertToMathematica[expr_] :=
	With[
		{
			reshape = Transpose[#, Reverse@Range@ArrayDepth@#]&,
			listToArray = First@Fold[Partition, #, Reverse[#2]]&
		},
		Block[{matCell,matArray,matStruct,matSparseArray,matLogical,matString,matUnknown},
			$OutputIsCell = !FreeQ[expr, matCell];

			matCell[list_, dim_] := listToArray[list,dim];
			matStruct[list_, dim_] := listToArray[list,dim];
			matSparseArray[jc_, ir_, vals_, dims_] := Transpose@SparseArray[Automatic, dims, 0, {1, {jc, List /@ ir + 1}, vals}];

			matLogical[list_, dim_] := matLogical[reshape@list];
			matLogical[list_] /; $ReturnLogicalsAs0And1 := list;
			matLogical[list_] /; !$ReturnLogicalsAs0And1 := list /. {1 -> True, 0 -> False};

			matArray[list_, dim_] := reshape@list;
			matString[str_] := str;
			matUnknown[u_] := (Message[engGet::unimpl, u]; $Failed);

			expr /. {{x_?NumericQ}} :> x
		]
	]

End[]

EndPackage[]
