(* Numerical array unit tests *)
(* R. Menon *)

Needs["MATLink`"];
Quiet@OpenMATLAB[];

(* Receive 2D array from MATLAB *)
Test[
	MEvaluate["r2DMat = magic(5);"];
	r2DMma = MGet["r2DMat"]
	,
	{
		{17., 24., 1., 8., 15.},
		{23., 5., 7., 14., 16.},
		{4., 6., 13., 20., 22.},
		{10., 12., 19., 21., 3.},
		{11., 18., 25., 2., 9.}
	}
	,
	TestID->"Arrays-20130222-L5P1F6"
]

(* Send 2D array back to MATLAB *)
Test[
	MSet["r2DMma", r2DMma];
	MEvaluate["result = isequal(r2DMat, r2DMma);"];
	MGet["result"]
	,
	True
	,
	TestID->"Arrays-20130222-F9S1L1"
]

(* Receive 2D complex array from MATLAB *)
Test[
	MEvaluate["c2DMat = magic(4) + 1i*magic(4);"];
	c2DMma = MGet["c2DMat"]
	,
	{
		{16. + 16. I, 2. + 2. I, 3. + 3. I, 13. + 13. I},
		{5. + 5. I, 11. + 11. I, 10. + 10. I, 8. + 8. I},
		{9. + 9. I, 7. + 7. I, 6. + 6. I, 12. + 12. I},
		{4. + 4. I, 14. + 14. I, 15. + 15. I, 1. + 1. I}
	}
	,
	TestID->"Arrays-20130222-J9Z1Q3"
]

(* Send complex 2D array back to MATLAB *)
Test[
	MSet["c2DMma", c2DMma];
	MEvaluate["result = isequal(c2DMat, c2DMma);"];
	MGet["result"]
	,
	True
	,
	TestID->"Arrays-20130223-O9F5I8"
]

(* Check indexing (proper transposition) when receiving a 5-D array from MATLAB *)
Test[
	MEvaluate["
		r5DMat = randn([2,3,4,5,6]);
		r1 = r5DMat(2,:,3,1,4);
		r2 = r5DMat(:,3,4,3,2);
		r3 = squeeze(r5DMat(1,1,:,4,1));
		r4 = squeeze(r5DMat(2,2,3,:,6));
		r5 = r5DMat(:,:,4,2,5);
		r6 = squeeze(r5DMat(2,3,:,:,3));
	"];
	{r5DMma, r1, r2, r3, r4, r5, r6} = MGet[{"r5DMat", "r1", "r2", "r3", "r4", "r5", "r6"}];
	{
		r5DMma[[2,;;,3,1,4]]   == Flatten@r1,
		r5DMma[[;;,3,4,3,2]]   == Flatten@r2,
		r5DMma[[1,1,;;,4,1]]   == Flatten@r3,
		r5DMma[[2,2,3,;;,6]]   == Flatten@r4,
		r5DMma[[;;,;;,4,2,5]]  == r5,
		r5DMma[[2,3,;;,;;,3]]  == r6
	}
	,
	ConstantArray[True, 6]
	,
	TestID->"Arrays-20130222-R7N4U5"
]

(* Check indexing (proper transposition) when sending a 5-D array to MATLAB *)
Test[
	MSet["r5DMma", r5DMma];
	MEvaluate["result = isequal(r5DMma, r5DMat);"];
	MGet["result"]
	,
	True
	,
	TestID->"Arrays-20130223-N8D1Z7"
]

(* Check indexing (proper transposition) when receiving a complex 5-D array from MATLAB *)
Test[
	MEvaluate["
		c5DMat = randn([2,3,4,5,6]) + 1i*randn([2,3,4,5,6]);;
		c1 = c5DMat(2,:,3,1,4);
		c2 = c5DMat(:,3,4,3,2);
		c3 = squeeze(c5DMat(1,1,:,4,1));
		c4 = squeeze(c5DMat(2,2,3,:,6));
		c5 = c5DMat(:,:,4,2,5);
		c6 = squeeze(c5DMat(2,3,:,:,3));
	"];
	{c5DMma, c1, c2, c3, c4, c5, c6} = MGet[{"c5DMat", "c1", "c2", "c3", "c4", "c5", "c6"}];
	{
		c5DMma[[2,;;,3,1,4]]   == Flatten@c1,
		c5DMma[[;;,3,4,3,2]]   == Flatten@c2,
		c5DMma[[1,1,;;,4,1]]   == Flatten@c3,
		c5DMma[[2,2,3,;;,6]]   == Flatten@c4,
		c5DMma[[;;,;;,4,2,5]]  == c5,
		c5DMma[[2,3,;;,;;,3]]  == c6
	}
	,
	ConstantArray[True, 6]
	,
	TestID->"Arrays-20130223-K8G0M6"
]

(* Check indexing (proper transposition) when sending a complex 5-D array to MATLAB *)
Test[
	MSet["c5DMma", c5DMma];
	MEvaluate["result = isequal(c5DMma, c5DMat);"];
	MGet["result"]
	,
	True
	,
	TestID->"Arrays-20130223-B8M2N5"
]
