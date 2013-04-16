(* Mathematica Test File *)

(* WARNING

   Don't run this on a machine with less than 8 GB of RAM!

   These tests are not included in MATLink.mt because they
   take an extreme amount of memory to run and will
   only work on 64-bit platforms.
   They also take a much longer time to run than the rest.     
*)
   
Quiet@OpenMATLAB[]

Test[
	MEvaluate["clear x; x=1:300000000;"];
	TrueQ[MGet["x"] == Range[300000000]]
	,
	True
	,
	TestID -> "LargeArray-20130414-E0D8V6"
]

Test[
	MEvaluate["clear x; x=speye(100000000);"];
	TrueQ[MGet["x"] == SparseArray[{i_,i_}->1, 100000000*{1,1}]]
	,
	True
	,
	TestID -> "LargeArray-20130415-T1Y1O7"
]

MEvaluate["clear all"]

Quiet@CloseMATLAB[]
