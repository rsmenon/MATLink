/* mengine.tm
 *
 * Copyright (c) 2014 Sz. Horvát and R. Menon
 *
 * See the file LICENSE.txt for copying permission.
 */

:Evaluate:		Begin["MATLink`Engine`"]

:Begin:
:Function:		eng_open
:Pattern:		engOpen[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_open_q
:Pattern:		engOpenQ[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_close
:Pattern:		engClose[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_evaluate
:Pattern:		engEvaluate[command_]
:Arguments:		{command}
:ArgumentTypes:	{UTF8String}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_getbuffer
:Pattern:		engGetBuffer[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_get
:Pattern:		engGet[name_String]
:Arguments:		{name}
:ArgumentTypes:	{String}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_RealArray
:Pattern:		engMakeRealArray[list_, dims_]
:Arguments:		{list, dims}
:ArgumentTypes:	{Real64List, Integer32List}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_ComplexArray
:Pattern:		engMakeComplexArray[real_, imag_, dims_]
:Arguments:		{real, imag, dims}
:ArgumentTypes:	{Real64List, Real64List, Integer32List}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_Logical
:Pattern:		engMakeLogical[list_, dims_]
:Arguments:		{list, dims}
:ArgumentTypes:	{Integer16List, Integer32List}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_SparseReal
:Pattern:		engMakeSparseReal[ir_, jc_, real_, m_, n_]
:Arguments:		{ir, jc, real, m, n}
:ArgumentTypes:	{Integer32List, Integer32List, Real64List, Integer32, Integer32}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_SparseComplex
:Pattern:		engMakeSparseComplex[ir_, jc_, real_, imag_, m_, n_]
:Arguments:		{ir, jc, real, imag, m, n}
:ArgumentTypes:	{Integer32List, Integer32List, Real64List, Real64List, Integer32, Integer32}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_SparseLogical
:Pattern:		engMakeSparseLogical[ir_, jc_, logicals_, m_, n_]
:Arguments:		{ir, jc, logicals, m, n}
:ArgumentTypes:	{Integer32List, Integer32List, Integer16List, Integer32, Integer32}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_String
:Pattern:		engMakeString[string_]
:Arguments:		{string}
:ArgumentTypes:	{UCS2String}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_Struct
:Pattern:		engMakeStruct[fields_, handles_, dims_]
:Arguments:		{fields, handles, dims}
:ArgumentTypes:	{Manual}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_make_Cell
:Pattern:		engMakeCell[handles_, dims_]
:Arguments:		{handles, dims}
:ArgumentTypes:	{Integer32List, Integer32List}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_clean_handles
:Pattern:		engCleanHandles[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_get_handles
:Pattern:		engGetHandles[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_set
:Pattern:		engSet[name_, handle_]
:Arguments:		{name, handle}
:ArgumentTypes:	{String, Integer32}
:ReturnType:	Manual
:End:


:Begin:
:Function:		eng_set_visible
:Pattern:		engSetVisible[value_]
:Arguments:		{value}
:ArgumentTypes:	{Integer32}
:ReturnType:	Manual
:End:


:Begin:
:Function:		setup_abort_handler
:Pattern:		engSetupAbortHandler[]
:Arguments:		{}
:ArgumentTypes:	{}
:ReturnType:	Integer
:End:

:Evaluate:		End[]
