(* Mathematica Test File *)

(* This is for testing Mathematica -> MATLAB -> Mathematica roundtripping
   This should usually work, but not in every case:

   MSet["x", x] 
   MGet["x"] === x

*)

(* MATLAB -> Mathematica -> MATLAB roundtripping is not feasible so it's a non-goal *)

Quiet@OpenMATLAB[]


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
   as those characters are not supported by either Mathematica or MATLAB.
   In other words: do not include anything that's encoded as 4 bytes
   instead of 2 bytes in UTF-16. *)
Test[
	x = "\[OSlash]\[ARing]\[AE] \[ODoubleAcute]\[UAcute] \[CapitalEpsilon]\[Lambda]\[Lambda]\[Eta]\[Nu]\[Iota]\[Kappa]\:03ac \:4e2d\:6587 a\:026ap\:02b0i\:02d0e\:026a";
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
	MGet["x"] == N[x]
	,
	True
	,
	TestID->"Roundtripping-20130414-T2J0O5"
]


(* Sparse array with rationals *)
Test[
	x = SparseArray[{i_, j_} :> i/j, {4, 6}];
	MSet["x", x];
	MGet["x"] == N[x]
	,
	True
	,
	TestID->"Roundtripping-20130414-X1C0F6"
]


(* single element sparse *)
Test[
	x = N@SparseArray[{{Pi}}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-O5I5Q8"
]


(* empty sparse array *)
Test[
	x = SparseArray@ConstantArray[0, {17,23}];
	MSet["x", x];
	MGet["x"] == x
	,
	True
	,
	TestID->"Roundtripping-20130415-F8L4M1"
]


(* full sparse array *)
Test[
	x = N@SparseArray@RandomReal[1, {17,23}];
	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130415-K4J9S3"
]


(* sparse complex matrix *)
Test[
	With[{a = RandomReal[1, {31, 47}], b = RandomReal[1, {31, 47}]},
	 x = SparseArray[a UnitStep[a - 0.9] + I b UnitStep[b - 0.9]]
	 ];	
 	MSet["x", x];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130414-X9F2J8"
]


(* sparse complex vector *)
Test[
	With[{a = RandomReal[1, {31}], b = RandomReal[1, {31}]},
	 x = SparseArray[a UnitStep[a - 0.9] + I b UnitStep[b - 0.9]]
	 ];	
 	MSet["x", x];
	MGet["x"] == {x}
	,
	True
	,
	TestID->"Roundtripping-20130414-Y3B3T9"
]



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


(* Sparse logical matrix, False default element *)
Test[
	x = SparseArray[{i_, j_} :> PrimeQ[i + j], {13, 27}, False];
	MSet["x", x];
	MGet["x"] == x
	,
	True
	,
	TestID->"Roundtripping-20130414-T1V8B8"
]


(* Sparse logical matrix, 0 default element *)
Test[
	x = SparseArray[{i_, j_} :> PrimeQ[i + j], {13, 27}];
	MSet["x", x];
	MGet["x"] == x
	,
	True
	,
	TestID->"Roundtripping-20130414-Y8M0D0"
]


(* Sparse logical vector, False default element *)
Test[
	x = SparseArray[i_ :> PrimeQ[i], {100}, False];
	MSet["x", x];
	Normal@MGet["x"]
	,
	{Normal[x]}
	,
	TestID->"Roundtripping-20130414-Z4D5A0"
]


(* Sparse logical vector, 0 default element *)
Test[
	x = SparseArray[i_ :> PrimeQ[i], {100}];
	MSet["x", x];
	Normal@MGet["x"]
	,
	{Normal[x]}
	,
	TestID->"Roundtripping-20130414-S3H3L1"
]



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


(* empty cell *)
Test[
	x = {};
	MSet["x", MCell[x]];
	MGet["x"]
	,
	x
	,
	TestID->"Roundtripping-20130415-M1G7C3"
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


(* SOME REALISTIC EXAMPLES *)

(* MATPOWER 4 -- http://www.pserc.cornell.edu/matpower/
   This is a list containing the input case data and the solution structure for
   'case9' included in the MATPOWER package.
   
   Data obtained by
   c=case9;
   r=runpf(c);
   
   x = {MGet["c"], MGet["r"]}
 *)
 
 Test[
   x = {{"version" -> "2", "baseMVA" -> 100., "bus" -> {{1., 3., 0., 0., 0., 0., 1., 
   1., 0., 345., 1., 1.1, 0.9}, {2., 2., 0., 0., 0., 0., 1., 1., 0., 345., 1., 
   1.1, 0.9}, {3., 2., 0., 0., 0., 0., 1., 1., 0., 345., 1., 1.1, 0.9}, {4., 
   1., 0., 0., 0., 0., 1., 1., 0., 345., 1., 1.1, 0.9}, {5., 1., 90., 30., 0., 
   0., 1., 1., 0., 345., 1., 1.1, 0.9}, {6., 1., 0., 0., 0., 0., 1., 1., 0., 
   345., 1., 1.1, 0.9}, {7., 1., 100., 35., 0., 0., 1., 1., 0., 345., 1., 1.1, 
   0.9}, {8., 1., 0., 0., 0., 0., 1., 1., 0., 345., 1., 1.1, 0.9}, {9., 1., 
   125., 50., 0., 0., 1., 1., 0., 345., 1., 1.1, 0.9}}, 
  "gen" -> {{1., 0., 0., 300., -300., 1., 100., 1., 250., 10., 0., 0., 0., 0., 
   0., 0., 0., 0., 0., 0., 0.}, {2., 163., 0., 300., -300., 1., 100., 1., 300., 
   10., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.}, {3., 85., 0., 300., -300., 
   1., 100., 1., 270., 10., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.}}, 
  "branch" -> {{1., 4., 0., 0.0576, 0., 250., 250., 250., 0., 0., 1., -360., 
   360.}, {4., 5., 0.017, 0.092, 0.158, 250., 250., 250., 0., 0., 1., -360., 
   360.}, {5., 6., 0.039, 0.17, 0.358, 150., 150., 150., 0., 0., 1., -360., 
   360.}, {3., 6., 0., 0.0586, 0., 300., 300., 300., 0., 0., 1., -360., 360.}, 
   {6., 7., 0.0119, 0.1008, 0.209, 150., 150., 150., 0., 0., 1., -360., 360.}, 
   {7., 8., 0.0085, 0.072, 0.149, 250., 250., 250., 0., 0., 1., -360., 360.}, 
   {8., 2., 0., 0.0625, 0., 250., 250., 250., 0., 0., 1., -360., 360.}, {8., 
   9., 0.032, 0.161, 0.306, 250., 250., 250., 0., 0., 1., -360., 360.}, {9., 
   4., 0.01, 0.085, 0.176, 250., 250., 250., 0., 0., 1., -360., 360.}}, 
  "areas" -> {1., 5.}, "gencost" -> {{2., 1500., 0., 3., 0.11, 5., 150.}, {2., 
   2000., 0., 3., 0.085, 1.2, 600.}, {2., 3000., 0., 3., 0.1225, 1., 335.}}}, 
 {"version" -> "2", "baseMVA" -> 100., "bus" -> {{1., 3., 0., 0., 0., 0., 1., 
   1., 0., 345., 1., 1.1, 0.9}, {2., 2., 0., 0., 0., 0., 1., 
   0.9999999999999998, 9.668741126628106, 345., 1., 1.1, 0.9}, {3., 2., 0., 0., 
   0., 0., 1., 1., 4.771073237177309, 345., 1., 1.1, 0.9}, {4., 1., 0., 0., 0., 
   0., 1., 0.9870068523919053, -2.406643919519416, 345., 1., 1.1, 0.9}, {5., 
   1., 90., 30., 0., 0., 1., 0.9754721770850528, -4.017264326707556, 345., 1., 
   1.1, 0.9}, {6., 1., 0., 0., 0., 0., 1., 1.0033754364528003, 
   1.925601686828556, 345., 1., 1.1, 0.9}, {7., 1., 100., 35., 0., 0., 1., 
   0.9856448817249467, 0.6215445553889178, 345., 1., 1.1, 0.9}, {8., 1., 0., 
   0., 0., 0., 1., 0.9961852458090698, 3.7991201926923055, 345., 1., 1.1, 0.9}, 
   {9., 1., 125., 50., 0., 0., 1., 0.9576210404299038, -4.349933576561019, 
   345., 1., 1.1, 0.9}}, "gen" -> {{1., 71.95470158922205, 24.068957772759347, 
   300., -300., 1., 100., 1., 250., 10., 0., 0., 0., 0., 0., 0., 0., 0., 0., 
   0., 0.}, {2., 163., 14.460119531125258, 300., -300., 1., 100., 1., 300., 
   10., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.}, {3., 85., 
   -3.6490255342095566, 300., -300., 1., 100., 1., 270., 10., 0., 0., 0., 0., 
   0., 0., 0., 0., 0., 0., 0.}}, "branch" -> {{1., 4., 0., 0.0576, 0., 250., 
   250., 250., 0., 0., 1., -360., 360., 71.95470158922205, 24.068957772759347, 
   -71.95470158922205, -20.75304453874029}, {4., 5., 0.017, 0.092, 0.158, 250., 
   250., 250., 0., 0., 1., -360., 360., 30.728280279736804, 
   -0.5858508226421093, -30.554685558054462, -13.687950499421412}, {5., 6., 
   0.039, 0.17, 0.358, 150., 150., 150., 0., 0., 1., -360., 360., 
   -59.445314441944774, -16.31204950057859, 60.89386583276656, 
   -12.427469531088468}, {3., 6., 0., 0.0586, 0., 300., 300., 300., 0., 0., 1., 
   -360., 360., 84.99999999999997, -3.649025534209542, -84.99999999999996, 
   7.890678351196236}, {6., 7., 0.0119, 0.1008, 0.209, 150., 150., 150., 0., 
   0., 1., -360., 360., 24.10613416723337, 4.536791179891428, 
   -24.010647778941582, -24.400762440776795}, {7., 8., 0.0085, 0.072, 0.149, 
   250., 250., 250., 0., 0., 1., -360., 360., -75.98935222105757, 
   -10.599237559222836, 76.49556434279408, 0.2562394697225474}, {8., 2., 0., 
   0.0625, 0., 250., 250., 250., 0., 0., 1., -360., 360., -162.99999999999963, 
   2.2761898794086703, 162.99999999999966, 14.460119531125285}, {8., 9., 0.032, 
   0.161, 0.306, 250., 250., 250., 0., 0., 1., -360., 360., 86.5044356572031, 
   -2.532429349130052, -84.03988686535038, -14.281982987799392}, {9., 4., 0.01, 
   0.085, 0.176, 250., 250., 250., 0., 0., 1., -360., 360., -40.96011313464419, 
   -35.71801701219859, 41.2264213094819, 21.338895361384118}}, 
  "areas" -> {1., 5.}, "gencost" -> {{2., 1500., 0., 3., 0.11, 5., 150.}, {2., 
   2000., 0., 3., 0.085, 1.2, 600.}, {2., 3000., 0., 3., 0.1225, 1., 335.}}, 
  "order" -> {"bus" -> {"e2i" -> SparseArray[Automatic, {9, 1}, 0., 
        {1, {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, {{1}, {1}, {1}, {1}, {1}, {1}, 
          {1}, {1}, {1}}}, {1., 2., 3., 4., 5., 6., 7., 8., 9.}}], 
      "i2e" -> {{1.}, {2.}, {3.}, {4.}, {5.}, {6.}, {7.}, {8.}, {9.}}, 
      "status" -> {"on" -> {{1.}, {2.}, {3.}, {4.}, {5.}, {6.}, {7.}, {8.}, 
         {9.}}, "off" -> {}}}, "gen" -> {"e2i" -> {{1.}, {2.}, {3.}}, 
      "i2e" -> {{1.}, {2.}, {3.}}, "status" -> {"on" -> {{1.}, {2.}, {3.}}, 
        "off" -> {}}}, "branch" -> 
     {"status" -> {"on" -> {{1.}, {2.}, {3.}, {4.}, {5.}, {6.}, {7.}, {8.}, 
         {9.}}, "off" -> {}}}, "areas" -> 
     {"status" -> {"on" -> 1., "off" -> {}}}, "state" -> "e", 
    "int" -> {"bus" -> {{1., 3., 0., 0., 0., 0., 1., 1., 0., 345., 1., 1.1, 
       0.9}, {2., 2., 0., 0., 0., 0., 1., 0.9999999999999998, 
       9.668741126628106, 345., 1., 1.1, 0.9}, {3., 2., 0., 0., 0., 0., 1., 1., 
       4.771073237177309, 345., 1., 1.1, 0.9}, {4., 1., 0., 0., 0., 0., 1., 
       0.9870068523919053, -2.406643919519416, 345., 1., 1.1, 0.9}, {5., 1., 
       90., 30., 0., 0., 1., 0.9754721770850528, -4.017264326707556, 345., 1., 
       1.1, 0.9}, {6., 1., 0., 0., 0., 0., 1., 1.0033754364528003, 
       1.925601686828556, 345., 1., 1.1, 0.9}, {7., 1., 100., 35., 0., 0., 1., 
       0.9856448817249467, 0.6215445553889178, 345., 1., 1.1, 0.9}, {8., 1., 
       0., 0., 0., 0., 1., 0.9961852458090698, 3.7991201926923055, 345., 1., 
       1.1, 0.9}, {9., 1., 125., 50., 0., 0., 1., 0.9576210404299038, 
       -4.349933576561019, 345., 1., 1.1, 0.9}}, "branch" -> {{1., 4., 0., 
       0.0576, 0., 250., 250., 250., 0., 0., 1., -360., 360., 
       71.95470158922205, 24.068957772759347, -71.95470158922205, 
       -20.75304453874029}, {4., 5., 0.017, 0.092, 0.158, 250., 250., 250., 0., 
       0., 1., -360., 360., 30.728280279736804, -0.5858508226421093, 
       -30.554685558054462, -13.687950499421412}, {5., 6., 0.039, 0.17, 0.358, 
       150., 150., 150., 0., 0., 1., -360., 360., -59.445314441944774, 
       -16.31204950057859, 60.89386583276656, -12.427469531088468}, {3., 6., 
       0., 0.0586, 0., 300., 300., 300., 0., 0., 1., -360., 360., 
       84.99999999999997, -3.649025534209542, -84.99999999999996, 
       7.890678351196236}, {6., 7., 0.0119, 0.1008, 0.209, 150., 150., 150., 
       0., 0., 1., -360., 360., 24.10613416723337, 4.536791179891428, 
       -24.010647778941582, -24.400762440776795}, {7., 8., 0.0085, 0.072, 
       0.149, 250., 250., 250., 0., 0., 1., -360., 360., -75.98935222105757, 
       -10.599237559222836, 76.49556434279408, 0.2562394697225474}, {8., 2., 
       0., 0.0625, 0., 250., 250., 250., 0., 0., 1., -360., 360., 
       -162.99999999999963, 2.2761898794086703, 162.99999999999966, 
       14.460119531125285}, {8., 9., 0.032, 0.161, 0.306, 250., 250., 250., 0., 
       0., 1., -360., 360., 86.5044356572031, -2.532429349130052, 
       -84.03988686535038, -14.281982987799392}, {9., 4., 0.01, 0.085, 0.176, 
       250., 250., 250., 0., 0., 1., -360., 360., -40.96011313464419, 
       -35.71801701219859, 41.2264213094819, 21.338895361384118}}, 
      "gen" -> {{1., 71.95470158922205, 24.068957772759347, 300., -300., 1., 
       100., 1., 250., 10., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.}, {2., 
       163., 14.460119531125258, 300., -300., 1., 100., 1., 300., 10., 0., 0., 
       0., 0., 0., 0., 0., 0., 0., 0., 0.}, {3., 85., -3.6490255342095566, 
       300., -300., 1., 100., 1., 270., 10., 0., 0., 0., 0., 0., 0., 0., 0., 
       0., 0., 0.}}, "gencost" -> {{2., 1500., 0., 3., 0.11, 5., 150.}, {2., 
       2000., 0., 3., 0.085, 1.2, 600.}, {2., 3000., 0., 3., 0.1225, 1., 
       335.}}, "areas" -> {1., 5.}}}, "et" -> 0.1546730000000025, 
  "success" -> 1.}};
  	MSet["x", x];
	MGet["x"],
	x,
	TestID->"Roundtripping-20130414-R5G5N9"
 ]
 
 
 
(* after all the tests have run, check that there are no
   stray handles left in the mengine process *)
Test[
	MATLink`Engine`engGetHandles[]
	,
	{}
	,
	TestID -> "Roundtripping-20130416-P9Z2R3"	
]


(* check that no stray temporary variables are left
   in the MATLAB workspace *)
Test[
	Select[Flatten[{MFunction["who"][]}], StringMatchQ[#, "MATLink*"] &]
	,
	{}
	,
	TestID -> "Roundtripping-20130416-H3I4I1"
]
 
 Quiet@CloseMATLAB[]
 