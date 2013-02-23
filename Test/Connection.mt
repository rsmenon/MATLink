(* Test connection with the Engine and MATLAB *)
(* R. Menon *)

Test[
	Needs["MATLink`"];
	OpenMATLAB[];
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, True, True}
	,
	TestID->"Connection-20130222-O9F3F2"
]
