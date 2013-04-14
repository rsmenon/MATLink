(* Mathematica Test File *)

Needs["MATLink`"]

Quiet@OpenMATLAB[]

(* s(2).b is not a special case internally *)
Test[
	MEvaluate["s=struct('a', 1); s = [s s]; s(1).b=2;"];
	MGet["s"]
	,
	{{"a"->1., "b"->2.},{"a"->1., "b"->{}}}
	,
	TestID->"GetSet-20130414-J6E4Y3"
]


(* CHECK THAT DIMENSIONS AND TRANSPOSITIONS ARE CORRECT *)

size = Composition[Round, MFunction["size"]]

(* dense numerical arrays *)

Test[
	dims = {7,11};
	size@ConstantArray[0, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-S2R7F0"
]


Test[
	dims = {7,11,13};
	size@ConstantArray[0, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-H9B1F8"
]


Test[
	dims = {7,11,13,17};
	size@ConstantArray[0, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-V5W6P3"
]


(* dense logical arrays *)
Test[
	dims = {7,11};
	size@ConstantArray[True, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-U4G2L1"
]


Test[
	dims = {7,11,13,17};
	size@ConstantArray[True, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-T6C6B7"
]


(* sparse numerical arrays *)
Test[
	dims = {7,11};
	size@SparseArray@ConstantArray[0, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-S7C4T2"
]


(* sparse logical arrays *)
Test[
	dims = {7,11};
	size@SparseArray@ConstantArray[True, dims]
	,
	dims
	,
	TestID->"GetSet-20130414-Z4X0Y5"
]


(* Note: if this test fails, it does not necessarily indicate breakage,
   but I want to be alerted about any changes in behaviour.
   Contact me if this fails. -- Szabolcs *)
Test[
	size[{}]
	,
	{1,0}
	,
	TestID->"GetSet-20130414-X8N1P0"
]


(* CELLS *)

(* cell matrix of empty matrices *)
Test[
	MEvaluate["c=cell(2,3);"];
	MGet["c"]
	,
	{{{},{},{}}, {{},{},{}}}
	,
	TestID->"GetSet-20130414-L6W1T9"
]

(* cell vector of empty matrices *)
Test[
	MEvaluate["c=cell(1,3);"];
	MGet["c"]
	,
	{{},{},{}}
	,
	TestID->"GetSet-20130414-K5Z6V7"
]

(* TODO higher dimensional cell of empty matrices *)


(* cell matrix *)
Test[
	MEvaluate["c={1 2 3; 4 5 6};"];
	MGet["c"]
	,
	N@{{1, 2, 3}, {4, 5, 6}}
	,
	TestID->"GetSet-20130414-U0A1N3"
]

(* cell vector *)
Test[
	MEvaluate["c={1 2 3};"];
	MGet["c"]
	,
	N@{1, 2, 3}
	,
	TestID->"GetSet-20130414-K3P0N0"
]

(* TODO higher dimensional non-empty cell *)


(* STRUCTS *)

(* struct with no fields *)
Test[
	MEvaluate["s=struct();"];
	MGet["s"]
	,
	{}
	,
	TestID->"GetSet-20130414-L0A8S3"
]


(* struct matrix with no fields *)
Test[
	MEvaluate["s=struct(); s = [s s s; s s s]"];
	MGet["s"]
	,
	{{{},{},{}}, {{},{},{}}}
	,
	TestID->"GetSet-20130414-V6F1P1"
]


(* struct vector with no fields *)
Test[
	MEvaluate["s=struct(); s = [s s s]"];
	MGet["s"]
	,
	{{},{},{}}
	,
	TestID->"GetSet-20130414-L0U7T7"
]


(* struct matrix *)
Test[
	MEvaluate["s=struct('a', 1); s = [s s s; s s s]"];
	MGet["s"]
	,
	{{{"a" -> 1., "a" -> 1., "a" -> 1.}, {"a" -> 1., "a" -> 1., "a" -> 1.}}}
	,
	TestID->"GetSet-20130414-Q4S3X4"
]


(* struct vector *)
Test[
	MEvaluate["s=struct('a', 1); s = [s s s]"];
	MGet["s"]
	,
	{{"a" -> 1.}, {"a" -> 1.}, {"a" -> 1.}}
	,
	TestID->"GetSet-20130414-O8E3B0"
]

(* TODO higher dimensional struct *)