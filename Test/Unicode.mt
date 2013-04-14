(* Mathematica Test File *)

Quiet@OpenMATLAB[]

size = Composition[Round, MFunction["size"]]


(* Latin 1 only *)
Test[
	size["áéí"]
	,
	{1,3}
	,
	TestID -> "Unicode-20130414-R5O1F3"
]


(* Lots of non-Latin-1 *)
Test[
	s = "áéí őű aɪpʰiːeɪ Ελληνικά 汉语";
	size[s]
	,
	{1,StringLength[s]}
	,
	TestID -> "Unicode-20130414-Y5K4M8"
]


(* in case Mathematica fails to interpret this file as UTF-8 *)
Test[
	s = "汉语";
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
	s="汉语";
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
	s = "áéí őű aɪpʰiːeɪ Ελληνικά 汉语";
	MEvaluate["clear s; s = '"<> s <>"'"];
	MGet["s"]
	,
	s
	,
	TestID -> "Unicode-20130414-S8C4W6"
]


Quiet@CloseMATLAB[]
