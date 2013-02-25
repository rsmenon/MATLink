(* :Title: MATLink *)
(* :Context: MATLink` *)
(* :Authors:
	R. Menon (rsmenon@icloud.com)
	Sz. Horvát (szhorvat@gmail.com)
*)
(* :Package Version: 0.1 *)
(* :Mathematica Version: 9.0 *)

BeginPackage["MATLink`"]

ConnectMATLAB::usage =
	"ConnectMATLAB[] establishes a connection with the MATLink engine, but does not open an instance of MATLAB."

DisconnectMATLAB::usage =
	"DisconnectMATLAB[] closes an existing connection with the MATLink engine."

OpenMATLAB::usage =
	"OpenMATLAB[] opens an instance of MATLAB and allows you to access its workspace."

CloseMATLAB::usage =
	"CloseMATLAB[] closes a previously opened instance of MATLAB (opened via MATLink)."

MGet::usage =
	"MGet[var] imports the MATLAB variable named \"var\" into Mathematica. MGet is Listable."

MSet::usage =
	"MSet[var, expr] exports the value in expr and saves it in a variable named \"var\" in MATLAB's workspace."

MEvaluate::usage =
	"MEvaluate[expr] evaluates a valid MATLAB expression (entered as a string) and displays an error otherwise."

MScript::usage =
	"MScript[filename, expr] creates a MATLAB script named \"filename\" with the contents in expr (string) and stores it on MATLAB's path, but does not evaluate it. These files will be removed when the MATLink engine is closed."

MFunction::usage =
	"Create a link to a MATLAB function for use from Mathematica."

$ReturnLogicalsAs0And1::usage =
	"If $ReturnLogicalsAs0And1 is set to True, MATLAB logicals will be returned as 0 or 1, and True or False otherwise."

$DefaultMATLABDirectory::usage =
	"Path to the default MATLAB directory. The MATLink engine calls the MATLAB executable located in this path."

mcell::usage = "" (* TODO Make this private before release *)

Begin["`Developer`"]
$ApplicationDirectory = DirectoryName@$InputFileName;
$EngineSourceDirectory = FileNameJoin[{$ApplicationDirectory, "Engine", "src"}];
$DefaultMATLABDirectory = "/Applications/MATLAB_R2012b.app/";

CompileMEngine[] :=
	Block[{dir = Directory[]},
		SetDirectory[$EngineSourceDirectory];
		PrintTemporary["Compiling the MATLink Engine from source...\n"];
		Run["make"];
		DeleteFile@FileNames@"*.o";
		Run["mv mengine ../"];
		SetDirectory@dir
	]

CleanupTemporaryDirectories[] :=
	Module[{},
		DeleteDirectory[#, DeleteContents -> True] & /@ FileNames@FileNameJoin[{$TemporaryDirectory,"MATLink*"}];
	]

End[]

Begin["`Private`"]
AppendTo[$ContextPath, "MATLink`Developer`"];

(* Directories and helper functions/variables *)
EngineBinaryExistsQ[] := FileExistsQ@FileNameJoin[{$ApplicationDirectory, "Engine", "mengine"}];

(* Set these variables only once per session.
This is to avoid losing connection/changing temporary directory because the user used Get instead of Needs *)
If[!TrueQ[MATLABInstalledQ[]],
	MATLABInstalledQ[] = False;
	$openLink = {};
	$sessionID = "";
	$temporaryVariablePrefix = "";
	$sessionTemporaryDirectory = "";,

	General::needs = "MATLink is already loaded. Remember to use Needs instead of Get.";
	Message[General::needs]
]

EngineLinkQ[LinkObject[link_String, _, _]] := ! StringFreeQ[link, "mengine.sh"];

(* To close previously opened links that were not terminated properly (possibly from a crash) *)
cleanupOldLinks[] :=
	Module[{},
		LinkClose /@ Select[Links[], EngineLinkQ];
		MATLABInstalledQ[] = False;
	]

MScriptQ[name_String] /; MATLABInstalledQ[] :=
	FileExistsQ[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]]

randomString[n_Integer:50] :=
	StringJoin@RandomSample[Join[#, ToLowerCase@#] &@CharacterRange["A", "Z"], n]

(* Check MATLAB code for syntax errors before evaluating.
This is necessary because a bug in the engine causes it to hang if there is a syntax error. *)
errorsInMATLABCode[cmd_String] :=
	Module[
		{
			file = MScript[randomString[], cmd],
			config = FileNameJoin[{$ApplicationDirectory, "Kernel","MLintErrors.txt"}],
			result
		},
		eval@ToString@StringForm[
			"`1` = checkcode('`2`','-id','-config=`3`')",
			First@file, file["AbsolutePath"],config
		];
		result = List@@MGet@First@file;
		eval@ToString@StringForm["clear `1`", First@file];
		DeleteFile@file["AbsolutePath"];
		If[result =!= {}, "message" /. Flatten@result, None]
	]

(* Common error messages *)
General::wspo = "The MATLAB workspace is already open."
General::wspc = "The MATLAB workspace is already closed."
General::engo = "There is an existing connection to the MATLAB engine."
General::engc = "Not connected to the MATLAB engine."
General::nofn = "The `1` \"`2`\" does not exist."
General::owrt = "An `1` by that name already exists. Use \"Overwrite\" \[Rule] True to overwrite."

(* Connect/Disconnect MATLAB engine *)
ConnectMATLAB[] /; EngineBinaryExistsQ[] && !MATLABInstalledQ[] :=
	Module[{},
		cleanupOldLinks[];
		$openLink = Install@FileNameJoin[{$ApplicationDirectory, "Engine", "mengine.sh"}];
		$sessionID = StringJoin[
			 IntegerString[{Most@DateList[]}, 10, 2],
			 IntegerString[List @@ Rest@$openLink]
		];
		$temporaryVariablePrefix = "MATLink" <> $sessionID;
		$sessionTemporaryDirectory = FileNameJoin[{$TemporaryDirectory, "MATLink" <> $sessionID}];
		CreateDirectory@$sessionTemporaryDirectory;
		MATLABInstalledQ[] = True;
	]

ConnectMATLAB[] /; EngineBinaryExistsQ[] && MATLABInstalledQ[] := Message[ConnectMATLAB::engo]

ConnectMATLAB[] /; !EngineBinaryExistsQ[] :=
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

$ReturnLogicalsAs0And1 = False;

(* MGet & MSet *)
SyntaxInformation[MGet] = {"ArgumentsPattern" -> {_}};
SetAttributes[MGet,Listable]

MGet[var_String] /; MATLABInstalledQ[] :=
	convertToMathematica@get[var] /; engineOpenQ[]

MGet[_String] /; MATLABInstalledQ[] := Message[MGet::wspc] /; !engineOpenQ[]
MGet[_String] /; !MATLABInstalledQ[] := Message[MGet::engc]

SyntaxInformation[MSet] = {"ArgumentsPattern" -> {_, _}};

MSet[var_String, expr_] /; MATLABInstalledQ[] :=
	Internal`WithLocalSettings[
		Null,
		mset[var, convertToMATLAB[expr]],
		MATLink`Engine`engCleanHandles[]	(* prevent memory leaks *)
	] /; engineOpenQ[]

MSet[___] /; MATLABInstalledQ[] := Message[MSet::wspc] /; !engineOpenQ[]
MSet[___] /; !MATLABInstalledQ[] := Message[MSet::engc]

(* MEvaluate *)
MEvaluate::errx = "``" (* Fill in when necessary with the error that MATLAB reports *)

SyntaxInformation[MEvaluate] = {"ArgumentsPattern" -> {_}};

MEvaluate[cmd_String] /; MATLABInstalledQ[] :=
	Catch@Module[{result, error, id = randomString[]},
		If[
			TrueQ[(error = errorsInMATLABCode@cmd) === None],
			result = eval@StringJoin["
				try
					", cmd, "
				catch ex
					sprintf('%s%s%s', '", id, "', ex.getReport,'", id, "')
				end
			"],
			Message[MEvaluate::errx, error];Throw[$Failed]
		];
		If[StringFreeQ[result,id],
			StringReplace[result, StartOfString~~">> " -> ""],
			First@StringCases[result, __ ~~ id ~~ x__ ~~ id ~~ ___ :> (Message[MEvaluate::errx, x];Throw[$Failed])]
		]
	] /; engineOpenQ[]

MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && MScriptQ[name] :=
	eval[name] /; engineOpenQ[]

MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && !MScriptQ[name] :=
	Message[MEvaluate::nofn,"MScript", name]

MEvaluate[___] /; MATLABInstalledQ[] := Message[MEvaluate::wspc] /; !engineOpenQ[]
MEvaluate[___] /; !MATLABInstalledQ[] := Message[MEvaluate::engc]

(* MScript & MFunction *)
Options[MScript] = {"Overwrite" -> False};

MScript[name_String, cmd_String, OptionsPattern[]] /; MATLABInstalledQ[] :=
	Module[{file},
		file = OpenWrite[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}], CharacterEncoding -> "UTF-8"];
		WriteString[file, cmd];
		Close[file];
		MScript[name]
	] /; (!MScriptQ[name] || OptionValue["Overwrite"])

MScript[name_String, cmd_String, OptionsPattern[]] /; MATLABInstalledQ[] :=
	Message[MScript::owrt, "MScript"] /; MScriptQ[name] && !OptionValue["Overwrite"]

MScript[name_String, cmd_String, OptionsPattern[]] /; !MATLABInstalledQ[] := Message[MScript::engc]

MScript[name_String]["AbsolutePath"] /; MScriptQ[name] :=
	FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]

Options[MFunction] = {"Output" -> True, "OutputArguments" -> 1};
(* Since MATLAB allows arbitrary function definitions depending on the number of output arguments, we force the user to explicitly specify the number of outputs if it is different from the default value of 1. *)

MFunction[name_String, OptionsPattern[]][args___] /; MATLABInstalledQ[] :=
	Module[{nIn = Length[{args}], nOut = OptionValue["OutputArguments"], vars, output},
		vars = Table[ToString@Unique[$temporaryVariablePrefix], {nIn + nOut}];
		Thread[MSet[vars[[;;nIn]], {args}]];
		MEvaluate[StringJoin["[", Riffle[vars[[-nOut;;]], ","], "]=", name, "(", Riffle[vars[[;;nIn]], ","], ")"]];
		output = MGet /@ vars[[-nOut;;]];
		MEvaluate[StringJoin["clear ", Riffle[vars, " "]]];
		If[nOut == 1, First@output, output]
	] /; OptionValue["Output"]

MFunction[name_String, OptionsPattern[]][args___] /; MATLABInstalledQ[] :=
	With[{vars = Table[ToString@Unique[$temporaryVariablePrefix], {Length[{args}]}]},
		Thread[MSet[vars, {args}]];
		MEvaluate[StringJoin[name, "(", Riffle[vars, ","], ")"]];
		MEvaluate[StringJoin["clear ", Riffle[vars, " "]]];
	] /; !OptionValue["Output"]

MFunction[name_String, OptionsPattern[]][args___] /; MATLABInstalledQ[] := Message[MFunction::wspc] /; !engineOpenQ[]
MFunction[name_String, OptionsPattern[]][args___] /; !MATLABInstalledQ[] := Message[MFunction::engc]

mcell[] :=
	Module[{},
		CellPrint@Cell[
			TextData[""],
			"Program",
			Evaluatable->True,
			CellEvaluationFunction -> (MEvaluate[ToString[#, CharacterEncoding -> "UTF-8"]]&), (* TODO figure out how to avoid conversion to \[AAcute], \[UDoubleAcute], etc. forms *)
			CellFrameLabels -> {{None,"MATLAB"},{None,None}}
		];
		SelectionMove[EvaluationNotebook[], All, EvaluationCell];
		NotebookDelete[];
		SelectionMove[EvaluationNotebook[], Next, CellContents]
	]


End[]

(* Low level functions strongly tied with the C++ code are part of this context *)
Begin["`Engine`"]
AppendTo[$ContextPath, "MATLink`Private`"]
Needs["MATLink`DataTypes`"]

(* Assign to symbols defined in `Private` *)
engineOpenQ[] /; MATLABInstalledQ[] := engOpenQ[]
engineOpenQ[] /; !MATLABInstalledQ[] := False
openEngine = engOpen;
closeEngine = engClose;
eval = engEvaluate;
get = engGet;
set = engSet;

engGet::unimpl = "Translating the MATLAB type \"`1`\" is not supported"

(* CONVERT DATA TYPES TO MATHEMATICA *)

(* The following mat* heads are inert and indicate the type of the MATLAB data returned
   by the engine.  They must be part of the MATLink`Engine` context.
   Evaluation is only allowed inside the convertToMathematica function,
   which converts it to their final Mathematica form.  engGet[] will always return
   either $Failed, or an expression wrapped in one of the below heads.
   Note that structs and cells may contain subxpressions of other types.
*)

convertToMathematica[expr_] :=
	With[
		{
			reshape = Switch[#2,
				{_,1}, #[[All, 1]],
				_, Transpose[#, Reverse@Range@ArrayDepth@#]
			]&,
			listToArray = First@Fold[Partition, #, Reverse[#2]]&
		},
		Block[{matCell,matArray,matStruct,matSparseArray,matLogical,matString,matUnknown},

			matCell[list_, dim_] := MCell[ listToArray[list,dim] ~reshape~ dim ];

			matStruct[list_, dim_] := MStruct@@ listToArray[list,dim] ~reshape~ dim;

			matSparseArray[jc_, ir_, vals_, dims_] := Transpose@SparseArray[Automatic, dims, 0, {1, {jc, List /@ ir + 1}, vals}];

			matLogical[list_, {1,1}] := matLogical@list[[1,1]];
			matLogical[list_, dim_] := matLogical[list ~reshape~ dim];
			matLogical[list_] /; $ReturnLogicalsAs0And1 := list;
			matLogical[list_] /; !$ReturnLogicalsAs0And1 := list /. {1 -> True, 0 -> False};

			matArray[list_, {1,1}] := list[[1,1]];
			matArray[list_, dim_] := list ~reshape~ dim;

			matString[str_] := str;

			matUnknown[u_] := (Message[engGet::unimpl, u]; $Failed);

			expr
		]
	]


(* CONVERT DATA TYPES TO MATLAB *)

AppendTo[$ContextPath, "MATLink`DataTypes`"]
AppendTo[$ContextPath, "MATLink`DataTypes`Private`"]

complexArrayQ[arr_] := Developer`PackedArrayQ[arr, Complex] || (Not@Developer`PackedArrayQ[arr] && Not@FreeQ[arr, Complex])

booleanQ[True | False] = True
booleanQ[_] = False

ruleQ[_Rule] = True
ruleQ[_] = False

handleQ[_handle] = True
handleQ[_] = False

(* the convertToMATLAB function will always end up with a handle[] if it was successful *)
mset[name_String, handle[h_Integer]] := engSet[name, h]
mset[name_, _] := $Failed

convertToMATLAB[expr_] :=
	Module[{structured,reshape = Composition[Flatten, Transpose[#, Reverse@Range@ArrayDepth@#]&]},
		structured = restructure[expr];

		Block[{MArray, MSparseArray, MLogical, MSparseLogical, MString, MCell, MStruct},
		    MArray[vec_?VectorQ] := MArray[{vec}];
			MArray[arr_] :=
				With[{list = reshape@Developer`ToPackedArray@N[arr]},
					If[ complexArrayQ[list],
						engMakeComplexArray[Re[list], Im[list], Reverse@Dimensions[arr]],
						engMakeRealArray[list, Reverse@Dimensions[arr]]
					]
				];

			MString[str_String] := engMakeString[str];

			MLogical[arr_] := engMakeLogical[Boole@reshape@arr, Reverse@Dimensions@arr];

			MCell[vec_?VectorQ] := MCell[{vec}];
			MCell[arr_?(ArrayQ[#, _, handleQ]&)] :=
				engMakeCell[reshape@arr /. handle -> Identity, Reverse@Dimensions[arr]];

			structured (* $Failed falls through *)
		]
	]

restructure[expr_] := Catch[dispatcher[expr], $dispTag]

dispatcher[expr_] :=
	Switch[
		expr,

		(* packed arrays are always numeric *)
		_?Developer`PackedArrayQ,
		MArray[expr],

		(* catch sparse arrays early *)
		_SparseArray,
		handleSparse[expr],

		(* empty *)
		Null | {},
		MArray[{}],

		(* scalar *)
		_?NumericQ,
		MArray[{expr}],

		(* non-packed numerical array *)
		_?(ArrayQ[#, _, NumericQ] &),
		MArray[expr],

		(* logical scalar *)
		True | False,
		MLogical[{expr}],

		(* logical array *)
		_?(ArrayQ[#, _, booleanQ] &),
		MLogical[expr],

		(* string *)
		_String,
		MString[expr],

		(* string array *)
		(* _?(ArrayQ[#, _, StringQ] &),
		MString[expr], *)

		(* struct -- may need recursion *)
		MStruct[_],
		MStruct[handleStruct@First[expr]],

		(* struct *)
		_?(VectorQ[#, ruleQ] &),
		MStruct[handleStruct[expr]],

		(* cell -- may need recursion *)
		MCell[_],
		MCell[handleCell@First[expr]],

		(* cell *)
		_List,
		MCell[handleCell[expr]],

		(* assumed already handled, no recursion needed; only MCell and MStruct may need recursion *)
		_MArray | _MLogical | _MSparseArray | _MSparseLogical | _MString,
		expr,

		_,
		Throw[$Failed, $dispTag]
	]

handleSparse[arr_SparseArray ? (VectorQ[#, NumericQ]&) ] := MSparseArray[SparseArray[{arr}]] (* convert to matrix *)
handleSparse[arr_SparseArray ? (MatrixQ[#, NumericQ]&) ] := MSparseArray[arr]
handleSparse[_] := Throw[$Failed, $dispTag] (* higher dim sparse arrays or non-numerical ones are not supported *)

handleStruct[_] := Throw[$Failed, $dispTag] (* not YET supported *)

handleCell[list_List] := dispatcher /@ list
handleCell[expr_] := dispatcher[expr]

End[]

EndPackage[]
