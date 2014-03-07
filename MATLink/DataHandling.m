(* :Context: MATLink`DataHandling` *)
(* Low level functions strongly tied with the C++ code are part of this context *)

BeginPackage["MATLink`DataHandling`", {"MATLink`"}]

convertToMathematica::usage = ""
convertToMATLAB::usage = ""

Needs["MATLink`Developer`"]
AppendTo[$ContextPath, "MATLink`Engine`"]
Begin["`Private`"]

(* CONVERT DATA TYPES TO MATHEMATICA *)

(* The following mat* heads are inert and indicate the type of the MATLAB data returned
   by the engine. They must be part of the MATLink`Engine` context.
   Evaluation is only allowed inside the convertToMathematica function,
   which converts it to their final Mathematica form. engGet[] will always return
   either $Failed, or an expression wrapped in one of the below heads.
   Note that structs and cells may contain subexpressions of other types.
*)

convertToMathematica[expr_] :=
        With[
            {
                reshape = Switch[#2,
                    {_,1}, #[[All, 1]],
                    _, Transpose[#, Reverse@Range@Length[#2]]
                ]&,
                listToArray = First@Fold[Partition, #, Reverse[#2]]&
            },
            Block[{matCell, matStruct, matArray, matSparseArray, matLogical, matSparseLogical, matString, matCharArray, matUnknown},

                matCell[list_, {1,1}] := list[[1]];
                matCell[list_, dim_] := listToArray[list,dim] ~reshape~ dim;

                matStruct[list_, {1,1}] := list[[1]];
                matStruct[list_, dim_] := listToArray[list,dim] ~reshape~ dim;

                matSparseArray[jc_, ir_, vals_, dims_] := Transpose@SparseArray[Automatic, dims, 0, {1, {jc, List /@ ir + 1}, vals}];

                matSparseLogical[jc_, ir_, vals_, dims_] := Transpose@SparseArray[Automatic, dims, False, {1, {jc, List /@ ir + 1}, vals /. 1 -> True}];

                matLogical[list_, {1,1}] := matLogical@list[[1,1]];
                matLogical[list_, dim_] := matLogical[list ~reshape~ dim];
                matLogical[list_] := list /. {1 -> True, 0 -> False};

                matArray[list_, {1,1}] := list[[1,1]];
                matArray[list_, dim_] := list ~reshape~ dim;

                matString[str_] := str;

                matCharArray[list_, dim_] := listToArray[list,dim] ~reshape~ dim;

                matUnknown[u_] := (message[MGet::unimpl, u]["error"]; $Failed);

                expr
            ]
        ]

(* CONVERT DATA TYPES TO MATLAB *)

complexArrayQ[arr_] := Developer`PackedArrayQ[arr, Complex] || (Not@Developer`PackedArrayQ[arr] && Not@FreeQ[arr, Complex])

booleanQ[True | False] = True
booleanQ[_] = False

ruleQ[_Rule] = True
ruleQ[_] = False

handleQ[_handle] = True
handleQ[_] = False

structHandleQ[_String -> _handle] = True
structHandleQ[_] = False

(* the convertToMATLAB function will always end up with a handle[] if it was successful *)
convertToMATLAB[expr_] :=
        Module[{structured,reshape = Composition[Flatten, Transpose[#, Reverse@Range@ArrayDepth@#]&]},
            structured = restructure[expr];

            Block[{MArray, MSparseArray, MLogical, MSparseLogical, MString, MCell, MStruct},
                MArray[vec_?VectorQ] := MArray[{vec}];
                MArray[arr_] :=
                        With[{list = reshape@Developer`ToPackedArray@N[arr]},
                            If[ complexArrayQ[list],
                                engMakeComplexArray[Re[list], Im[list], Reverse@Dimensions[arr]],
                                engMakeRealArray[list, Reverse@Dimensions[arr]]
                            ]
                        ];

                MString[str_String] := engMakeString[str];

                (* TODO allow casting array of 0s and 1s to logical *)
                MLogical[vec_?VectorQ] := MLogical[{vec}];
                MLogical[arr_] := engMakeLogical[Boole@reshape@arr, Reverse@Dimensions@arr];

                MCell[vec_?VectorQ] := MCell[{vec}];
                MCell[arr_?(ArrayQ[#, _, handleQ]&)] :=
                        engMakeCell[reshape@arr /. handle -> Identity, Reverse@Dimensions[arr]];

                (* http://mathematica.stackexchange.com/questions/18081/how-to-interpret-the-fullform-of-a-sparsearray *)
                MSparseArray[HoldPattern@SparseArray[Automatic, {n_, m_}, def_ /; def==0, {1, {jc_, ir_}, val_}]] :=
                        With[{values=Developer`ToPackedArray@N[val]},
                            If[ complexArrayQ[values],
                                engMakeSparseComplex[Flatten[ir]-1, jc, Re[values], Im[values], m, n],
                                engMakeSparseReal[Flatten[ir]-1, jc, values, m, n]
                            ]
                        ];
                MSparseArray[_] := (message[MSet::spdef]["error"]; $Failed);

                MSparseLogical[HoldPattern@SparseArray[Automatic, {n_, m_}, False, {1, {jc_, ir_}, values_}]] :=
                        engMakeSparseLogical[Flatten[ir]-1, jc, Boole[values], m, n];

                (* If the default element of a sparse logical is not False, make it False *)
                MSparseLogical[arr_SparseArray] :=
                        MSparseLogical[SparseArray[arr, Dimensions[arr], False]];

                MStruct[rules_] :=
                        If[ !ArrayQ[rules, _, structHandleQ],
                            $Failed,
                            engMakeStruct[rules[[All,1]], rules[[All, 2, 1]], {1}]
                        ];

                structured (* $Failed falls through *)
            ]
        ]

restructure[expr_] := Catch[dispatcher[expr], $dispTag]

dispatcher[expr_] :=
        Switch[
            expr,

        (* packed arrays are always numeric *)
            _?Developer`PackedArrayQ,
            MArray[expr],

        (* catch sparse arrays early *)
            _SparseArray,
            handleSparse[expr],

        (* empty *)
            Null | {},
            MArray[{}],

        (* scalar *)
            _?NumericQ,
            MArray[{expr}],

        (* non-packed numerical array *)
            _?(ArrayQ[#, _, NumericQ] &),
            MArray[expr],

        (* logical scalar *)
            True | False,
            MLogical[{expr}],

        (* logical array *)
            _?(ArrayQ[#, _, booleanQ] &),
            MLogical[expr],

        (* string *)
            _String,
            MString[expr],

        (* string array *)
        (* _?(ArrayQ[#, _, StringQ] &),
		MString[expr], *)

        (* struct *)
            _?(VectorQ[#, ruleQ] &),
            MStruct[handleStruct[expr]],

        (* cell -- may need recursion *)
            MCell[_],
            MCell[handleCell@First[expr]],

        (* cell *)
            _List,
            MCell[handleCell[expr]],

        (* assumed already handled, no recursion needed; only MCell and MStruct may need recursion *)
            _MArray | _MLogical | _MSparseArray | _MSparseLogical | _MString,
            expr,

            _,

            message[MSet::unsupp, expr]["error"];  (* consider Style[expr, Blue] *)
            Throw[$Failed, $dispTag]
        ]

handleSparse[arr_SparseArray ? (VectorQ[#, NumericQ]&) ] := MSparseArray[Transpose@SparseArray[{arr}]] (* convert to matrix *)
handleSparse[arr_SparseArray ? (MatrixQ[#, NumericQ]&) ] := MSparseArray[Transpose@SparseArray[arr]] (* the extra SparseArray call gets rid of background elements *)
handleSparse[arr_SparseArray ? (VectorQ[#, booleanQ]&) ] := MSparseLogical[Transpose@SparseArray[{arr}]]
handleSparse[arr_SparseArray ? (MatrixQ[#, booleanQ]&) ] := MSparseLogical[Transpose@SparseArray[arr]]
handleSparse[_] := (message[MSet::sparse]["error"]; Throw[$Failed, $dispTag]) (* higher dim sparse arrays or non-numerical ones are not supported *)

handleStruct[rules_ ? (VectorQ[#, ruleQ]&)] :=
        With[{fields = rules[[All,1]]},
            If[ Not@MatchQ[fields, {___String}]
                ,
                message[MSet::fldstr,
                    Select[fields, Not@StringQ[#]&]
                ]["error"];
                Return[$Failed]
            ];
            With[{patt = RegularExpression["[a-zA-Z][a-zA-Z0-9_]*"]},
                If[ Not[And@@StringMatchQ[fields, patt]]
                    ,
                    message[MSet::fldnm,
                        Select[fields, Not@StringMatchQ[#, patt]& ]
                    ]["error"];
                    Return[$Failed]
                ]
            ];
            If[ Length@Union[fields] != Length[rules]
                ,
                message[MSet::flddup,
                    Cases[Tally[fields], {elem_, n_} /; n > 1][[All, 1]]
                ]["error"];
                Return[$Failed]
            ];
            Thread[fields -> (dispatcher /@ rules[[All, 2]])]
        ]

handleStruct[_] := (Assert["must never reach here"; False]; $Failed) (* TODO multi-element struct *)

handleCell[list_List] := dispatcher /@ list
handleCell[expr_] := dispatcher[expr]

End[]

EndPackage[]