(* :Title: MATLink *)
(* :Context: MATLink` *)
(* :Authors:
	R. Menon (rsmenon@icloud.com)
	Sz. Horvát (szhorvat@gmail.com)
*)
(* :Copyright: 2013 R. Menon and Sz. Horvát
    See the file LICENSE.txt for copying permission. *)

BeginPackage["MATLink`"]

Unprotect@"`*"
ClearAll@"`*"

ConnectEngine::usage =
	"ConnectEngine[] establishes a connection with the MATLink engine, but does not open an instance of MATLAB."

DisconnectEngine::usage =
	"DisconnectEngine[] closes an existing connection with the MATLink engine."

OpenMATLAB::usage =
	"OpenMATLAB[] opens an instance of MATLAB and allows you to access its workspace."

CloseMATLAB::usage =
	"CloseMATLAB[] closes a previously opened instance of MATLAB (opened via MATLink)."

CommandWindow::usage =
	"CommandWindow[\"Show\"] displays the MATLAB command window.\nCommandWindow[\"Hide\"] hides the MATLAB command window.\nThis function works only on Windows."

MGet::usage =
	"MGet[var] imports the MATLAB variable named \"var\" into Mathematica.  MGet is Listable."

MSet::usage =
	"MSet[var, expr] exports the value in expr and saves it in a variable named \"var\" in MATLAB's workspace."

MEvaluate::usage =
	"MEvaluate[expr] evaluates a valid MATLAB expression (entered as a string) and displays an error otherwise."

MScript::usage =
	"MScript[filename, expr] creates a MATLAB script named \"filename\" with the contents in expr (string) and stores it on MATLAB's path, but does not evaluate it. These files will be removed when the MATLink engine is closed.\nMScript[filename] represents a callable MATLAB script that can be passed to MEvaluate."

MFunction::usage =
	"MFunction[func] creates a link to a MATLAB function for use from Mathematica.\nMFunction[filename, expr] creates a script on MATLAB's path and returns MFunction[filename].  expr (string) must be a valid MATLAB function definition."

MATLink::usage =
	"MATLink refers to the MATLink package. Set cross-session package options to this symbol."

MCell::usage = "MCell[list] forces list to be interpreted as a MATLAB cell in MSet, MFunction, etc."

MATLABCell::usage = "MATLABCell[] creates a code cell that is evaluated using MATLAB."

Begin["`Information`"]
`$VersionNumber = 1.01
`$ReleaseNumber = "b"
`$CreationDate = "06 Mar 2014"
`$Version = ToString@StringForm["MATLink `1``2` for `3` (`4`)", `$VersionNumber, `$ReleaseNumber, $OperatingSystem, `$CreationDate]
`$HomePage := SystemOpen["http://matlink.org"]
End[] (* Information` *)

Begin["`Private`"]
Needs["MATLink`Developer`"];

(* Common error messages *)
MATLink::needs = "MATLink is already loaded. Remember to use Needs instead of Get.";
MATLink::errx = "``" (* Fill in when necessary with the error that MATLAB reports *)
MATLink::noconn = "MATLink has lost connection to the MATLAB engine; please restart MATLink to create a new connection. If this was a crash, then please try to reproduce it and open a new issue, making sure to provide all the details necessary to reproduce it."
MATLink::noerr = "No errors were found in the input expression. Check for possible invalid MATLAB assignments."
General::wspo = "The MATLAB workspace is already open."
General::wspc = "The MATLAB workspace is already closed."
General::engo = "There is an existing connection to the MATLAB engine."
General::engc = "Not connected to the MATLAB engine."
General::nofn = "The `1` \"`2`\" does not exist."
General::owrt = "An `1` by that name already exists. Use \"Overwrite\" -> True to overwrite."
General::badval = "Invalid option value `1` passed to `2`. Values must match the pattern `3`"
General::unkw = "`1` is an unrecognized argument"

(* Directories and helper functions/variables *)
EngineBinaryExistsQ[] := FileExistsQ[$BinaryPath];

(* Set these variables only once per session.
   This is to avoid losing connection/changing temporary directory because the user used Get instead of Needs *)
If[!TrueQ[MATLinkLoadedQ[]],
	MATLinkLoadedQ[] = True;
	MATLABInstalledQ[] = False;
	$openLink = {};
	$sessionID = "";
	$sessionTemporaryDirectory = "";
	writeLog["Loaded MATLink`", "user"];
	writeLog["Mathematica: " <> $Version, "info"];
	writeLog["MATLink: " <> MATLink`Information`$Version, "info"];
	writeLog["Settings: " <> ToString@Options@MATLink, "info"];,

	message[MATLink::needs]["warning"]
]

engineLinkQ[LinkObject[link_String, _, _]] := ! StringFreeQ[link, "mengine.sh"];

(* To close previously opened links that were not terminated properly (possibly from a crash) *)
cleanupOldLinks[] :=
	Module[{links = Select[Links[], engineLinkQ]},
		writeLog[ToString@StringForm["Closed `` old link objects.", Length@links]];
		LinkClose /@ links;
		MATLABInstalledQ[] = False;
	]

mscriptQ[name_String] /; MATLABInstalledQ[] :=
	FileExistsQ[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]]

mscriptQ[MScript[name_String, ___]] /; MATLABInstalledQ[] :=
	FileExistsQ[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]]

randomString[n_Integer:50] :=
	StringJoin@RandomSample[Join[#, ToLowerCase@#] &@CharacterRange["A", "Z"], n]

cleanOutput[str_String, file_String, script_] :=
	Block[{replaceFileName = If[script === "NoScript", Unevaluated@Sequence[], file -> "input"]},
		FixedPoint[
			StringReplace[#,
				{replaceFileName,
				"[\.08" ~~ Shortest[x__] ~~ "]" :> x,
				"Error: File: " ~~ $sessionTemporaryDirectory ~~ "/input.m " -> "",
				StartOfString ~~ ">> ".. :> ">> "}
			]&,
			str
		] /. "" -> Null
	]

validOptionsQ[func_Symbol, opts_List] :=
	With[{o = FilterRules[opts, Options[func]], patt = validOptionPatterns[func]},
		If[o =!= opts,
			message[func::optx, First@FilterRules[opts, Except[Options@func]], func]["error"]; False,
			FreeQ[If[MatchQ[#2, #1], True, message[func::badval, #2, func, #1]["error"];False] & @@@ (opts /. patt), False]
		]
	]

SetAttributes[switchAbort, HoldRest]
switchAbort[cond_, expr_, failExpr_] :=
	Switch[cond, True, expr, False, failExpr, $Failed, Abort[]]

(* Connect/Disconnect MATLAB engine *)
SyntaxInformation[ConnectEngine] = {"ArgumentsPattern" -> {}}

ConnectEngine[link_ : Automatic] /; EngineBinaryExistsQ[] && !MATLABInstalledQ[] :=
	Module[{},
		cleanupOldLinks[];
		$openLink = Switch[link,
			Automatic, Install@FileNameJoin[{$BinaryDirectory, If[$OperatingSystem === "Windows", "mengine.exe", "mengine.sh"]}],
			_, Install@LinkConnect@link
		];
		$sessionID = StringJoin[
			IntegerString[{Most@DateList[]}, 10, 2],
			IntegerString[List @@ Rest@$openLink],
			randomString[10]
		];
		$sessionTemporaryDirectory = FileNameJoin[{$TemporaryDirectory, "MATLink" <> $sessionID}];
		CreateDirectory@$sessionTemporaryDirectory;
		MATLABInstalledQ[] = True;
		writeLog["Connected to the MATLink Engine"];
	]

ConnectEngine[] /; EngineBinaryExistsQ[] && MATLABInstalledQ[] := message[ConnectEngine::engo]["warning"]

ConnectEngine[] /; !EngineBinaryExistsQ[] :=
	Module[{},
		writeLog["Compiled MATLink Engine on " <> $OperatingSystem, "matlink"];
		CompileMEngine[$OperatingSystem];
		ConnectEngine[];
	]

SyntaxInformation[DisconnectEngine] = {"ArgumentsPattern" -> {}}

DisconnectEngine[] /; MATLABInstalledQ[] :=
	Module[{},
		LinkClose@$openLink;
		$openLink = {};
		DeleteDirectory[$sessionTemporaryDirectory, DeleteContents -> True];
		MATLABInstalledQ[] = False;
		writeLog["Disconnected from the MATLink Engine"];
	]

DisconnectEngine[] /; !MATLABInstalledQ[] := message[DisconnectEngine::engc]["warning"]

(* Open/Close MATLAB Workspace *)
OpenMATLAB::noopen = "Could not open a connection to MATLAB."

SyntaxInformation[OpenMATLAB] = {"ArgumentsPattern" -> {}}

OpenMATLAB[] /; MATLABInstalledQ[] :=
	switchAbort[engineOpenQ[],
		message[OpenMATLAB::wspo]["warning"],

		Catch[
			Module[{},
				openEngine[];
				switchAbort[engineOpenQ[],
					writeLog["Opened MATLAB workspace"];
					MATLink`Engine`engSetupAbortHandler[];
					MFunction["addpath", "Output" -> False][$sessionTemporaryDirectory];
					MFunction["cd", "Output" -> False][Directory[]],

					message[OpenMATLAB::noopen]["fatal"];Throw[$Failed, $error]
				];
			],
			$error
		]
	]

OpenMATLAB[] /; !MATLABInstalledQ[] :=
	Module[{},
		ConnectEngine[];
		OpenMATLAB[];
	]

SyntaxInformation[CloseMATLAB] = {"ArgumentsPattern" -> {}}

CloseMATLAB[] /; MATLABInstalledQ[] :=
	switchAbort[engineOpenQ[],
		Module[{},
			writeLog["Closed MATLAB workspace"];
			closeEngine[]
		],
		message[CloseMATLAB::wspc]["warning"]
	]

CloseMATLAB[] /; !MATLABInstalledQ[] := message[CloseMATLAB::engc]["warning"];

(* Show or hide MATLAB command windows --- works on Windows only *)
CommandWindow::noshow = "Showing or hiding the MATLAB command window is only supported on Windows."
SyntaxInformation[CommandWindow] = {"ArgumentsPattern" -> {_}}

CommandWindow["Show"] := If[$OperatingSystem =!= "Windows", message[CommandWindow::noshow]["warning"], setVisible[1]]
CommandWindow["Hide"] := If[$OperatingSystem =!= "Windows", message[CommandWindow::noshow]["warning"], setVisible[0]]
CommandWindow[x_] := message[CommandWindow::unkw, x]["error"]
CommandWindow[_, x__] := message[CommandWindow::argx, "CommandWindow", Length@{x} + 1]["error"]

(* MGet *)
MGet::unimpl = "Translating the MATLAB type \"`1`\" is not supported"

SyntaxInformation[MGet] = {"ArgumentsPattern" -> {_}};
SetAttributes[MGet,Listable]

iMGet[var_String] := MATLink`DataHandling`convertToMathematica@get@var

MGet[var_String] /; MATLABInstalledQ[] :=
	switchAbort[engineOpenQ[],
		iMGet@var,
		message[MGet::wspc]["warning"]
	]

MGet[_String] /; !MATLABInstalledQ[] := message[MGet::engc]["warning"]

MGet[_, x__] := message[MGet::argx, "MGet", Length@{x} + 1]["error"]

(* MSet *)
MSet::sparse = "Unsupported sparse array; sparse arrays must be one or two dimensional, and must have either only numerical or only logical (True|False) elements."
MSet::spdef = "Unsupported sparse array; the default element in numerical sparse arrays must be 0."
MSet::flddup = "Duplicate field names not alowed in struct. The following duplicates were found: ``."
MSet::fldnm = "Struct field names must start with a letter and contain only letters, numbers or the _ character. The following struct field names are not valid: ``."
MSet::fldstr = "Struct field names must be strings. The following invalid field names were found: ``."
MSet::unsupp = "Unsupported data type. The expression \"``\" can't be converted."

SyntaxInformation[MSet] = {"ArgumentsPattern" -> {_, _}};

iMSet[var_String, expr_] :=
	Internal`WithLocalSettings[
		Null,
		set[var, MATLink`DataHandling`convertToMATLAB[expr]],
		cleanHandles[]	(* prevent memory leaks *)
	]

MSet[var_String, expr_] /; MATLABInstalledQ[] :=
	switchAbort[engineOpenQ[],
		iMSet[var, expr],
		message[MSet::wspc]["warning"]
	]

MSet[_] := message[MSet::argrx, "MSet", 1, 2]["error"]
MSet[_, _, __] := message[MSet::argrx, "MSet", "more than 2", 2]["error"]

MSet[___] /; !MATLABInstalledQ[] := message[MSet::engc]["warning"]

(* MEvaluate *)
SyntaxInformation[MEvaluate] = {"ArgumentsPattern" -> {_}};

iMEvaluate[cmd_String, script_ : Automatic] :=
	Catch[
		Module[{result, file, output = randomString[], id = randomString[], ex = randomString[]},
			Switch[script,
				Automatic, file = iMScript[randomString[], cmd],
				"NoScript", file = {cmd},
				_, Message[MEvaluate::unkw, script];Throw[$Failed,$error]
			];

			eval@StringJoin["
				try
					", output, " = evalc('", First@file, "');
				catch ", ex, "
					", output, " = sprintf('%s%s%s', '", id, "', ", ex, ".getReport,'", id, "');
				end
				clear ", ex
			];
            result = MGet[output];
            eval["clear " <> output];
			If[mscriptQ@file, DeleteFile@file];

			Switch[result,
				$Failed, (* TODO: In MEX, eval won't return anything, so figure out a way to handle failed calls. Tests that check for $Failed fail here. *)
				message[MATLink::noconn]["fatal"];
				Abort[],

				_,
				If[StringFreeQ[result,id],
					cleanOutput[result, First@file, script],

					First@StringCases[result, __ ~~ id ~~ x__ ~~ id ~~ ___ :>
						Block[{$MessagePrePrint = Identity},
							Message[MATLink::errx, cleanOutput[x, First@file, script]];
							Throw[$Failed, $error]
						]
					]
				]
			]
		],
		$error
	]

MEvaluate[cmd_String, script_ : Automatic] /; MATLABInstalledQ[] :=
	switchAbort[engineOpenQ[],
		iMEvaluate[cmd, script],
		message[MEvaluate::wspc]["warning"]
	]

MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && mscriptQ[name] :=
	switchAbort[engineOpenQ[],
		eval[name],
		message[MEvaluate::wspc]["warning"]
	]

MEvaluate[MScript[name_String]] /; MATLABInstalledQ[] && !mscriptQ[name] :=
	message[MEvaluate::nofn,"MScript", name]["error"]

MEvaluate[___] /; !MATLABInstalledQ[] := message[MEvaluate::engc]["warning"]

(* MScript & MFunction *)
Options[MScript] = {"Overwrite" -> False};
validOptionPatterns[MScript] = {"Overwrite" -> True | False};

SyntaxInformation[MScript] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}}

iMScript[name_String, cmd_String, overwrite_:False] :=
	Module[{file},
		file = OpenWrite[FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}], CharacterEncoding -> "UTF-8"];
		WriteString[file, cmd];
		Close[file];
		(* The following is necessary on Windows for MATLAB to pick up new script
		   It's skipped on OSX/Linux because it's slow on those platforms. *)
		If[$OperatingSystem === "Windows", MEvaluate["rehash", "NoScript"]];
		(* The following clears the script from memory to ensure MATLAB will reload it
		   exist() is used to avoid clearing variables of the same name by accident.
		   exist() is very slow on OSX/Linux so we only use it if the "Overwrite" -> True flag was used.
		   This avoids calling exist() when using MEvaluate[] *)
		If[overwrite && MFunction["exist"][name, "file"] == 2, MFunction["clear", "Output"->False][name]];
		MScript[name]
	]

MScript[name_String, cmd_String, opts : OptionsPattern[]] /; MATLABInstalledQ[] :=
	iMScript[name, cmd, OptionValue["Overwrite"]] /; (!mscriptQ[name] || OptionValue["Overwrite"]) && validOptionsQ[MScript, {opts}]

MScript[name_String, cmd_String, opts : OptionsPattern[]] /; MATLABInstalledQ[] :=
	Module[{},
		message[MScript::owrt, "MScript"]["warning"];
		MScript@name
	]  /; mscriptQ[name] && !OptionValue["Overwrite"] && validOptionsQ[MScript, {opts}]

MScript[name_String, cmd_String, OptionsPattern[]] /; !MATLABInstalledQ[] := message[MScript::engc]["warning"]

MScript[name_String]["AbsolutePath"] /; mscriptQ[name] :=
	FileNameJoin[{$sessionTemporaryDirectory, name <> ".m"}]

MScript[name_String]["AbsolutePath"] /; !mscriptQ[name] :=
	Module[{},
		message[MScript::nofn, "MScript", name]["error"];
		Throw[$Failed, $error]
	]

MScript /: DeleteFile[MScript[name_String]] :=
	Catch[
		DeleteFile[MScript[name]["AbsolutePath"]],
		$error
	]

Options[MFunction] = {"Overwrite" -> False, "Output" -> True, "OutputArguments" -> 1};
validOptionPatterns[MFunction] = {"Overwrite" -> True | False, "Output" -> True | False, "OutputArguments" -> _Integer?Positive};
(* Since MATLAB allows arbitrary function definitions depending on the number of output arguments,
	we force the user to explicitly specify the number of outputs if it is different from the default value of 1. *)

SyntaxInformation[MFunction] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}}

MFunction::args = "The arguments at positions `1` to \"`2`\" could not be translated to MATLAB."

MFunction[name_String, opts : OptionsPattern[]][args___] /; MATLABInstalledQ[] && validOptionsQ[MFunction, {opts}] :=
	switchAbort[engineOpenQ[],
		Switch[OptionValue["Output"],
			True,
			Module[{nIn = Length[{args}], nOut = OptionValue["OutputArguments"], vars, output, fails},
				vars = Table[randomString[], {nIn + nOut}];
				fails = Thread[iMSet[vars[[;;nIn]], {args}]];
				If[MemberQ[fails, $Failed],
					message[MFunction::args, Flatten@Position[fails, $Failed], name]["error"];
					output = ConstantArray[$Failed, nOut];,

					iMEvaluate[StringJoin["[", Riffle[vars[[-nOut;;]], ","], "]=", name, "(", Riffle[vars[[;;nIn]], ","], ");"], "NoScript"];
					output = iMGet /@ vars[[-nOut;;]];
				];
				iMEvaluate[StringJoin["clear ", Riffle[vars, " "]], "NoScript"];
				If[nOut == 1, First@output, output]
			],

			False,
			With[{vars = Table[randomString[], {Length[{args}]}]},
				fails = Thread[iMSet[vars, {args}]];
				If[MemberQ[fails, $Failed],
					message[MFunction::args, Position[fails, $Failed]]["error"],
					iMEvaluate[StringJoin[name, "(", Riffle[vars, ","], ");"], "NoScript"];
				];
				iMEvaluate[StringJoin["clear ", Riffle[vars, " "]], "NoScript"];
			]
		],

		message[MFunction::wspc]["warning"]
	]

MFunction[name_String, code_String, opts : OptionsPattern[]] /; MATLABInstalledQ[] && validOptionsQ[MFunction, {opts}] :=
	With[{anonymousQ = StringMatchQ[StringTrim@#, Verbatim@"@" ~~ __] &},
		If[anonymousQ@code,
			MEvaluate[name <> "=" <> code <> ";"],
			If[!mscriptQ[name] || OptionValue["Overwrite"],
				MScript[name, code, "Overwrite" -> True],
				message[MFunction::owrt, "MFunction"]["warning"]
			];
		];
		MFunction[name, Sequence @@ FilterRules[{opts}, Except["Overwrite"]]]
	]

MFunction[name_String, OptionsPattern[]][args___] /; !MATLABInstalledQ[] := message[MFunction::engc]["warning"]
MFunction[name_String, code_String, opts: OptionsPattern[]] /; !MATLABInstalledQ[] := message[MFunction::engc]["warning"]

MFunction /: DeleteFile[MFunction[name_String, ___]] :=
	Catch[
		DeleteFile[MScript[name]["AbsolutePath"]],
		$error
	]

MATLABCell[] :=
        Module[{},
            CellPrint@Cell[
                TextData[""],
                "Program",
                Evaluatable -> True,
                CellEvaluationFunction -> (MEvaluate@First@FrontEndExecute[FrontEnd`ExportPacket[Cell[#], "InputText"]] &),
                CellGroupingRules -> "InputGrouping",
                CellFrameLabels -> {{None,"MATLAB"},{None,None}}
            ];
            SelectionMove[EvaluationNotebook[], All, EvaluationCell];
            NotebookDelete[];
            SelectionMove[EvaluationNotebook[], Next, CellContents]
        ]

End[] (* MATLink`Private` *)

Begin["`Engine`"]
AppendTo[$ContextPath, "MATLink`Private`"]

(* Create engine symbols in the correct context *)
engCleanHandles::usage = ""
engClose::usage = ""
engEvaluate::usage = ""
engGet::usage = ""
engMakeCell::usage = ""
engMakeComplexArray::usage = ""
engMakeLogical::usage = ""
engMakeRealArray::usage = ""
engMakeSparseComplex::usage = ""
engMakeSparseLogical::usage = ""
engMakeSparseReal::usage = ""
engMakeString::usage = ""
engMakeStruct::usage = ""
engOpen::usage = ""
engOpenQ::usage = ""
engSet::usage = ""
engSetupAbortHandler::usage = ""
engSetVisible::usage = ""
matCell::usage = ""
matStruct::usage = ""
matArray::usage = ""
matSparseArray::usage = ""
matLogical::usage = ""
matSparseLogical::usage = ""
matString::usage = ""
matCharArray::usage = ""
matUnknown::usage = ""

(* Assign to symbols defined in MATLink`Private` *)
engineOpenQ[] /; MATLABInstalledQ[] :=
        With[{msgs = Unevaluated@{LinkObject::linkd, LinkObject::linkn}},
            Catch[
                Check[
                    engOpenQ[],

                    message[MATLink::noconn]["fatal"];
                    MATLABInstalledQ[] = False;
                    Throw[$Failed, $error],

                    msgs
                ] ~Quiet~ msgs,
                $error
            ]
        ]

engineOpenQ[] /; !MATLABInstalledQ[] := False
openEngine = engOpen;
closeEngine = engClose;

eval = engEvaluate;
get = engGet;
set[name_String, handle[h_Integer]] := engSet[name, h]
set[name_, _] := $Failed

cleanHandles = engCleanHandles;
setVisible = engSetVisible;

Needs["MATLink`DataHandling`"]

End[] (* Engine *)

SetAttributes[#, {Protected,ReadProtected}]& /@ Names["`*"];

EndPackage[] (* MATLink` *)
