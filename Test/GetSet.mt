(* Mathematica Test File *)

Quiet@OpenMATLAB[]

(* Get and Set failures *)
Test[
	MEvaluate["clear nonexistent;"];
	MGet["nonexistent"]
	,
	$Failed
	,
	TestID->"GetSet-20130418-X3Z1Z8"
]

Test[
	Clear[symbol];
	MSet["x", symbol]
	,
	$Failed
	,
	{MSet::unsupp}
	,
	TestID->"GetSet-20130418-J1V0P7"
]

Test[
	Clear[symbol];
	MSet["x", {symbol}]
	,
	$Failed
	,
	{MSet::unsupp}
	,
	TestID->"GetSet-20130418-Q1I3B2"
]

Test[
	Clear[symbol];
	MSet["x", 1/symbol]
	,
	$Failed
	,
	{MSet::unsupp}
	,
	TestID->"GetSet-20130418-U6V1A1"
]

Test[
	Clear[symbol];
	MSet["x", {"field" -> symbol}]
	,
	$Failed
	,
	{MSet::unsupp}
	,
	TestID->"GetSet-20130418-G8W1O4"
]

Test[
	MSet["x", {"field_1" -> 1}]
	,
	Null
	,
	TestID->"GetSet-20130419-G2Z3C1"
]

Test[
	MSet["x", {"1field" -> 1}]
	,
	$Failed
	,
	{MSet::fldnm}
	,
	TestID->"GetSet-20130419-B4C2W2"
]

Test[
	MSet["x", {"_field" -> 1}]
	,
	$Failed
	,
	{MSet::fldnm}
	,
	TestID->"GetSet-20130419-G6H9L1"
]

Test[
	MSet["x", {"*" -> 1}]
	,
	$Failed
	,
	{MSet::fldnm}
	,
	TestID->"GetSet-20130419-A1F7R6"
]

Test[
	Clear[field];
	MSet["x", {field -> 1}]
	,
	$Failed
	,
	{MSet::fldstr}
	,
	TestID->"GetSet-20130419-Q4B7U8"
]

Test[
	MSet["x", {1 -> 1}]
	,
	$Failed
	,
	{MSet::fldstr}
	,
	TestID->"GetSet-20130419-F1Y6I7"
]

Test[
	MSet["x", {"a" -> 1, "b" -> 0, "a" -> 1}]
	,
	$Failed
	,
	{MSet::flddup}
	,
	TestID->"GetSet-20130419-M2O9V8"
]


(* struct rules must be enclosed in a list 
   otherwise it's not clear if {"a" -> 1, "b" -> 1} 
   represents one or two structs *)
Test[
	MSet["x", "field" -> 1]
	,
	$Failed
	,
	{MSet::unsupp}
	,
	TestID->"GetSet-20130419-P6M2J4"
]

(* MATLAB doesn't support multidimensional sparse arrays *)
Test[
	MSet["x", SparseArray@RandomReal[1,{3,3,3}]]
	,
	$Failed
	,
	{MSet::sparse}
	,
	TestID->"GetSet-20130419-D3I6T9"
]

(* MATLAB doesn't support sparse arrays with a nonzero default element *)
Test[
	MSet["x", SparseArray[{1,0,1,0}, {4}, 1]]
	,
	$Failed
	,
	{MSet::spdef}
	,
	TestID->"GetSet-20130419-Z5Y0O8"
]


Test[
	MSet["x", 1]
	,
	Null
	,
	TestID->"GetSet-20130418-L7Q2O4"
]

(* Pi is a symbol, but it's numeric.  MSet must not throw an error *)
Test[
	MSet["x", Pi];
	MGet["x"]
	,
	N[Pi]
	,
	TestID->"GetSet-20130418-M4Y7C2"
]


(* NULL mxArray pointer *)
(* s(2).b is a special case internally (not repreented the same way as []) *)
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



Test[
	MEvaluate["x=1:7; a=x(3);"];
	MGet["x"][[3]] == MGet["a"] == 3
	,
	True
	,
	TestID->"GetSet-20130416-W1A9R4"
]


Test[
	MEvaluate["d=[7 11]; x=reshape(1:prod(d), d); a=x(3,4);"];
	MGet["x"][[3,4]] == MGet["a"]
	,
	True
	,
	TestID->"GetSet-20130416-K7C9N4"
]


Test[
	MEvaluate["d=[7 11 13]; x=reshape(1:prod(d), d); a=x(3,4,5);"];
	MGet["x"][[3,4,5]] == MGet["a"]
	,
	True
	,
	TestID->"GetSet-20130416-Q5P2M1"
]


Test[
	MEvaluate["d=[7 11 13 17]; x=reshape(1:prod(d), d); a=x(3,4,5,6);"];
	MGet["x"][[3,4,5,6]] == MGet["a"]
	,
	True
	,
	TestID->"GetSet-20130416-T6C4Z7"
]


(* NUMERIC TYPES *)

(* single *)
Test[
	MEvaluate["x = 1:(7*11); x = reshape(x, [7 11]); x=single(x);"];
	MGet["x"] 
	,
	N@Transpose@Partition[Range[7*11],7]
	,
	TestID->"GetSet-20130416-Y8L5Q7"
]

(* int16 *)
Test[
	MEvaluate["x = 1:(7*11); x = reshape(x, [7 11]); x=int16(x);"];
	MGet["x"] 
	,
	Transpose@Partition[Range[7*11],7]
	,
	TestID->"GetSet-20130416-I7U4Z7"
]

(* int32 *)
Test[
	MEvaluate["x = 1:(7*11); x = reshape(x, [7 11]); x=int32(x);"];
	MGet["x"] 
	,
	Transpose@Partition[Range[7*11],7]
	,
	TestID->"GetSet-20130416-V0Z2E0"
]

(* unimplemented
   This is now tested using utin8.  When uint8 gets implemented
   this will need to be changed. *)
Test[
	MEvaluate["x = uint32(7);"];
	MGet["x"]	
	,
	$Failed
	,
	{MGet::unimpl}
	,
	TestID -> "GetSet-20130416-N5U8J6"
]


(* CELLS *)

(* higher dimensional cell array of empty matrices *)
Test[
	MEvaluate["c=cell(2,3,5);"];
	MGet["c"]
	,
	{{{{}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}}},
     {{{}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}}}}
	,
	TestID->"GetSet-20130414-L6W1T9"
]

(* cell matrix of empty matrices *)
Test[
	MEvaluate["c=cell(2,3);"];
	MGet["c"]
	,
	{{{},{},{}}, {{},{},{}}}
	,
	TestID->"GetSet-20130416-J7K5E5"
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


(* higher dimensional non-empty cell *)
Test[
	MEvaluate["x = reshape(1:3*7*11, [3 7 11]); c=num2cell(x);"];
	MGet["c"]
	,
	MGet["x"]
	,
	TestID->"GetSet-20130416-Z1D5M9"
]


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


(* higher dimensional struct *)
(* also verifies hat struct and numarray dimensions are consistent *)
Test[
	MEvaluate["x=reshape(1:2*3*5*7,[2 3 5 7]);"];
	MEvaluate["s=struct('a',num2cell(x));"];
	"a" /. MGet["s"]
	,
	MGet["x"]
	,
	TestID->"GetSet-20130414-Q4S3X4"
]


(* higher dimensional struct *)
(* also verifies hat struct and numarray dimensions are consistent *)
Test[
	MEvaluate["x=reshape(1:2*3*5,[2 3 5]);"];
	MEvaluate["s=struct('a',num2cell(x));"];
	"a" /. MGet["s"]
	,
	MGet["x"]
	,
	TestID->"GetSet-20130416-M0K0S9"
]

(* struct matrix *)
(* also verifies hat struct and numarray dimensions are consistent *)
Test[
	MEvaluate["x=reshape(1:3*5,[3 5]);"];
	MEvaluate["s=struct('a',num2cell(x));"];
	"a" /. MGet["s"]
	,
	MGet["x"]
	,
	TestID->"GetSet-20130416-S3B7X7"
]


(* struct vector *)
(* also verifies hat struct and numarray dimensions are consistent *)
Test[
	MEvaluate["x=1:21;"];
	MEvaluate["s=struct('a',num2cell(x));"];
	"a" /. MGet["s"]
	,
	MGet["x"]
	,
	TestID->"GetSet-20130416-X8T6D4"
]


(* simple struct matrix *)
Test[
	MEvaluate["s=struct('a', 1); s = [s s s; s s s]"];
	MGet["s"]
	,
	{{{"a" -> 1.}, {"a" -> 1.}, {"a" -> 1.}}, {{"a" -> 1.}, {"a" -> 1.}, {"a" -> 1.}}}
	,
	TestID->"GetSet-20130416-K7O8U9"
]


(* simple struct vector *)
Test[
	MEvaluate["s=struct('a', 1); s = [s s s]"];
	MGet["s"]
	,
	{{"a" -> 1.}, {"a" -> 1.}, {"a" -> 1.}}
	,
	TestID->"GetSet-20130414-O8E3B0"
]


(* dimensional consistency between cell and logical *)
Test[
	MEvaluate["l=rand(1,3)<0.5; c=num2cell(l);"];
	MGet["c"]
	,
	MGet["l"]
	,
	TestID -> "GetSet-20130416-C0V0G6"
]


Test[
	MEvaluate["l=rand(2,3)<0.5; c=num2cell(l);"];
	MGet["c"]
	,
	MGet["l"]
	,
	TestID -> "GetSet-20130416-T7J1C2"
]


Test[
	MEvaluate["l=rand(2,3,5)<0.5; c=num2cell(l);"];
	MGet["c"]
	,
	MGet["l"]
	,
	TestID -> "GetSet-20130416-H4P5A5"
]


(* MGet should only return packed arrays *)

(* vector *)
Test[
	MEvaluate["x=1:100;"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-R0I5J8"
]

(* single precision *)
Test[
	MEvaluate["x=1:100; x=single(x);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-G6Y7C8"
]

(* int16 *)
Test[
	MEvaluate["x=1:100; x=int16(x);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-B5R9T2"
]

(* int32 *)
Test[
	MEvaluate["x=1:100; x=int32(x);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-K2F6H0"
]

(* matrix *)
Test[
	MEvaluate["x=rand(27,43);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-L7U6P9"
]

(* higer dimensional *)
Test[
	MEvaluate["x=rand(27,43,19);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-V5P0V8"
]

(* complex matrix *)
Test[
	MEvaluate["x=rand(51) + i*rand(51);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-Z0O1G5"
]

(* complex vector *)
Test[
	MEvaluate["x=rand(1,151) + i*rand(1,151);"];
	Developer`PackedArrayQ@MGet["x"]
	,
	True
	,
	TestID -> "GetSet-20130416-U3G0C5"
]



(* after all the tests have run, check that there are no
   stray handles left in the mengine process *)
Test[
	MATLink`Engine`engGetHandles[]
	,
	{}
	,
	TestID -> "GetSet-20130416-H8U8N8"	
]

(* check that no stray temporary variables are left
   in the MATLAB workspace *)
Test[
	Select[Flatten[{MFunction["who"][]}], StringMatchQ[#, "MATLink*"] &]
	,
	{}
	,
	TestID -> "GetSet-20130416-E8W8G4"
]

Quiet@CloseMATLAB[]
