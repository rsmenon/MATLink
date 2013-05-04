(* Mathematica Test File *)

Quiet@OpenMATLAB[]

size = Composition[Round, MFunction["size"]]


(* Latin 1 only *)
(* There was a crash that appeared when _only_ character codes 128-255 were present,
   but not if other unicode characters were included as well. *)
Test[
	size["\[AAcute]\[EAcute]\[IAcute]"]
	,
	{1,3}
	,
	TestID -> "Unicode-20130414-R5O1F3"
]


(* Lots of non-Latin-1 *)
Test[
	s = "\[AAcute]\[EAcute]\[IAcute] \[ODoubleAcute]\[UDoubleAcute] a\:026ap\:02b0i\:02d0e\:026a \[CapitalEpsilon]\[Lambda]\[Lambda]\[Eta]\[Nu]\[Iota]\[Kappa]\:03ac \:6c49\:8bed";
	size[s]
	,
	{1,StringLength[s]}
	,
	TestID -> "Unicode-20130414-Y5K4M8"
]


(* in case Mathematica fails to interpret this as a two-character string *)
Test[
	s = "\:6c49\:8bed";
	size[s]
	,
	{1,2}
	,
	TestID -> "Unicode-20130414-P6T3V8"
]


(* MEvaluate Unicode output *)
(* this would fail because currently unicode is disabled in MEvaluate's output *)
(*
Test[
	s="\:6c49\:8bed";
	MEvaluate["clear s"];
	MSet["s", s];
	StringMatchQ[MEvaluate["s"], s]
	,
	True
	,
	TestID -> "Unicode-20130414-G0H4F2"
]
*)


(* MEvaluate unicode input *)
Test[
	s = "\[AAcute]\[EAcute]\[IAcute] \[ODoubleAcute]\[UDoubleAcute] a\:026ap\:02b0i\:02d0e\:026a \[CapitalEpsilon]\[Lambda]\[Lambda]\[Eta]\[Nu]\[Iota]\[Kappa]\:03ac \:6c49\:8bed";
	MEvaluate["clear s; s = '"<> s <>"'"];
	MGet["s"]
	,
	s
	,
	TestID -> "Unicode-20130414-S8C4W6"
]


(* MEvaluate unicode input -- NoCheck version *)
Test[
	s = "\[AAcute]\[EAcute]\[IAcute] \[ODoubleAcute]\[UDoubleAcute] a\:026ap\:02b0i\:02d0e\:026a \[CapitalEpsilon]\[Lambda]\[Lambda]\[Eta]\[Nu]\[Iota]\[Kappa]\:03ac \:6c49\:8bed";
	MEvaluate["clear s; s = '"<> s <>"'", "NoScript"];
	MGet["s"]
	,
	s
	,
	TestID -> "Unicode-20130414-C0I6D8"
]


(* MScript unicode input (currently identical to MEvaluate) *)
Test[
	s = "\[AAcute]\[EAcute]\[IAcute] \[ODoubleAcute]\[UDoubleAcute] a\:026ap\:02b0i\:02d0e\:026a \[CapitalEpsilon]\[Lambda]\[Lambda]\[Eta]\[Nu]\[Iota]\[Kappa]\:03ac \:6c49\:8bed";
	MEvaluate@MScript["mltest", "clear s; s = '"<> s <>"'"];
	MGet["s"]
	,
	s
	,
	TestID -> "Unicode-20130414-F2F4H5"
]


(* after all the tests have run, check that there are no
   stray handles left in the mengine process *)
Test[
	MATLink`Engine`engGetHandles[]
	,
	{}
	,
	TestID -> "Unicode-20130416-R5H5G8"
]


(* check that no stray temporary variables are left
   in the MATLAB workspace *)
Test[
	Select[Flatten[{MFunction["who"][]}], StringMatchQ[#, "MATLink*"] &]
	,
	{}
	,
	TestID -> "Unicode-20130416-Q1J8H1"
]

Quiet@CloseMATLAB[]
