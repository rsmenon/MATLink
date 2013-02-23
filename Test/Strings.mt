(* Strings and string array unit tests *)
(* R. Menon *)

(* ASCII from MATLAB *)
Test[
	Needs["MATLink`"];
	Quiet@OpenMATLAB[];
	MEvaluate["asciiMat = char(0:127);"];
	MGet["asciiMat"]
	,
	FromCharacterCode@Range[0, 127]
	,
	TestID->"Strings-20130222-X7X4O5"
]

(* ASCII to MATLAB *)
Test[
	MSet["asciiMma", FromCharacterCode@Range[0, 127]];
	MEvaluate["result = strcmpi(asciiMat, asciiMma);"];
	MGet["result"]
	,
	True
	,
	TestID->"Strings-20130222-R8X2L9"
]

(* ISO Latin 1 from MATLAB *)
Test[
	Needs["MATLink`"];
	Quiet@OpenMATLAB[];
	MEvaluate["isolatin1Mat = char(129:255);"];
	MGet["isolatin1Mat"]
	,
	FromCharacterCode@Range[129, 255]
	,
	TestID->"Strings-20130223-E9A8J4"
]

(* ISO Latin 1 to MATLAB *)
Test[
	MSet["isolatin1Mma", FromCharacterCode@Range[129, 255]];
	MEvaluate["result = strcmpi(isolatin1Mat, isolatin1Mma);"];
	MGet["result"]
	,
	True
	,
	TestID->"Strings-20130223-I8B5Q1"
]