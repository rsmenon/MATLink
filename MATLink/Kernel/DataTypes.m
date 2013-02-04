BeginPackage["MATLink`DataTypes`"]

MCell::usage = ""
MStruct::usage = ""
MCellPart::usage = ""
MGetFields::usage = ""
MSetFields::usage = ""

Begin["`Private`"]
MakeBoxes[MCell[c___], form : StandardForm | TraditionalForm] :=
	MakeBoxes[AngleBracket@c, form];
MCell /: MCell[c___][[i_Integer]] := MCell[{c}[[i]]];
MCell /: MCell[c___][[i_]] := MCell[Sequence @@ {c}[[i]]];

MakeBoxes[s_MStruct, form: StandardForm | TraditionalForm] :=
	With[{list = List@@s /. Rule[_, val_] :> val},
		MakeBoxes[
		TableForm[
			list,
 			TableHeadings -> {ToString /@ Range@Length@s, s["FieldNames"]}
 		],
 		form
	]
	]
MStruct /: MStruct[s___]["FieldNames"] := MGetFields@MStruct@s
End[]

Begin["`FunctionsOnDataTypes`"]

MGetFields[s_MStruct] :=
	DeleteDuplicates@Cases[List@@s /. _MStruct -> {}, Rule[a_, _] :> a, Infinity]
End[]

EndPackage[]