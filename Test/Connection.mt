(* Test connection with the Engine and MATLAB *)
(* R. Menon *)

Needs["MATLink`"];

Test[
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, False, False}
	,
	TestID->"Connection-20130222-O9F3F2"
]

ConnectEngine[];
Test[
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, True, False}
	,
	TestID->"Connection-20130223-I1W3A9"
]

OpenMATLAB[];
Test[
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, True, True}
	,
	TestID->"Connection-20130223-B4B2U6"
]


CloseMATLAB[];
Test[
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, True, False}
	,
	TestID->"Connection-20130223-I6W6A1"
]

DisconnectEngine[];
Test[
	{MATLink`Private`EngineBinaryExistsQ[], MATLink`Private`MATLABInstalledQ[], MATLink`Private`engineOpenQ[]}
	,
	{True, False, False}
	,
	TestID->"Connection-20130223-I2E7T6"
]