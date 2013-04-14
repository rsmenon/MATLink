(* Mathematica Test File *)

(* This is for testing Mathematica -> MATLAB -> Mathematica roundtripping
   This should usually work, but not in every case:

   MSet["x", x] 
   MGet["x"] === x

*)

(* MATLAB -> Mathematica -> MATLAB roundtripping is not feasible so it's a non-goal *)

Needs["MATLink`"]

OpenMATLAB[]


(* real number *)
Test[
	x = N[Pi];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-W8H2U7"
]


(* complex number *)
Test[
	x = Sin[1. + I];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-Q2Z5V7"
]


(* empty array *)
Test[
	x = {};
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-T9B4T1"
]


(* nested empty array transforms to {} *)
Test[
	x = {{{}}};
	MSet["x", x];
	MGet["x"]
	,
	{}
	,
	TestID->"Roundtripping-20130414-R1W7C6"
]


(* row vector *)
Test[
	x = Range[10];
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-M7J6S7"
]


(* complex row vector *)
Test[
	x = RandomComplex[{-1 - I, 1 + I}, {10}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-J9D8D2"
]


(* row matrix is transformed to simple vector *)
Test[
	x = RandomReal[1, {1,10}];
	MSet["x", x];
	MGet["x"]
	,
	First[x]
	,
	TestID->"Roundtripping-20130414-C6E3Z4"
]


(* single element vector transforms to scalar *)
Test[
	x = {1.23};
	MSet["x", x];
	MGet["x"]
	,
	First[x]
	,
	TestID->"Roundtripping-20130414-M9K9H8"
]


(* single element matrix transforms to scalar *)
Test[
	x = {{-3.21}};
	MSet["x", x];
	MGet["x"]
	,
	x[[1,1]]
	,
	TestID->"Roundtripping-20130414-M7E2C5"
]


(* column vector *)
Test[
	x = List /@ Range[10];
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-C4H1E7"
]


(* complex column vector *)
Test[
	x = RandomComplex[{-1 - I, 1 + I}, {10, 1}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-U4S8H7"
]


(* non-square matrix *)
Test[
	x = {{1, 8, 6}, {0, 6, 7}, {8, 10, 4}, {8, 0, 3}, {7, 4, 1}};
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-Y7U6Z5"
]


(* complex non-square matrix *)
Test[
	x = RandomComplex[{-1 - I, 1 + I}, {13, 27}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-H1E2K9"
]


(* higher dimensional array *)
Test[
	x = RandomReal[1, {11, 17, 23}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-G4K2R9"
]


(* higher dimensional complex array *)
Test[
	x = RandomComplex[1+I, {11, 17, 23}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-M5R5R7"
]


(* ASCII string *)
Test[
	x = "The quick brown fox jumped over the lazy dog.";
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-M8M9F7"
]


(* Unicode string *)
(* Note: do not include anything outside of the basic multilingual plane here
   as those characters are not supported by either Mathematica or MATLAB *)
Test[
	x = "øåæ őú Ελληνικά 中文 aɪpʰiːeɪ";
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-O6W0G5"
]


(* Empty string *)
Test[
	x = "";
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-G1G4B6"
]


(* Sparse vector *)
Test[
	x = SparseArray@IntegerDigits[781279487213, 2];
	MSet["x", x];
	MGet["x"]
	,
	N@SparseArray[{x}] (* this is returned as a 1 by N matrix instead of a vector *)
	,
	TestID->"Roundtripping-20130414-Y2Q0L9"
]


(* Sparse column vector *)
Test[
	x = SparseArray[List /@ IntegerDigits[3481790182745, 2]];
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-T4S2V4"
]


(* Sparse matrix *)
Test[
	x = SparseArray[{i_, j_} /; 5 < Norm[{i, j}] < 8 :> N[i/j], {7, 8}];
	MSet["x", x];
	Normal@MGet["x"]
	,
	Normal@N[x]
	,
	TestID->"Roundtripping-20130414-T2J0O5"
]


(* Sparse array with rationals *)
Test[
	x = SparseArray[{i_, j_} :> i/j, {4, 6}];
	MSet["x", x];
	Normal@MGet["x"]
	,
	Normal@N[x]
	,
	TestID->"Roundtripping-20130414-X1C0F6"
]


(* TODO complex sparse *)


(* Logical scalar *)
Test[
	x = True;
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-I0Y8Y5"
]


(* Logical scalar *)
Test[
	x = False;
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-J7O8H5"
]


(* Logical row vector *)
Test[
	x = {True, True, False, False, True, False};
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-L3R8N2"
]


(* Logical column vector *)
Test[
	x = List /@ {True, True, False, False, True, False};
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-X1X4M6"
]


(* Logical non-square matrix *)
Test[
	x = Array[Mod[#1, #2] == 0 &, {50, 40}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-G9N1U9"
]


(* Logical higher-dimensional array *)
Test[
	x = Array[PrimeQ[#1 + #2] &, {41, 31, 19}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-Z8B4N7"
]


(* TODO sparse logical *)


(* Row cell of numbers *)
Test[
	x = {1, 2, 3};
	MSet["x", MCell[x]];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-X3D8J3"
]


(* Mixed data is sent as cell *)
Test[
	x = {"string", 1.23};
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-A7Z2I6"
]


(* Mixed data is sent as cell, nested *)
Test[
	x = {{"a", 1}, {2, 3}};
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-E3D2H4"
]


(* ragged array is sent as cell of arrays *)
(* we skip {} and {1} as those are handled specially *)
Test[
	x = Table[Range[i],{i,2,10}];
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-A9O2W8"
]


(* struct *)
Test[
	x = {"one" -> 1, "two" -> 2, "three" -> 3};
	MSet["x", x];
	MGet["x"]
	,
	N[x]
	,
	TestID->"Roundtripping-20130414-P5R8G1"
]