
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
:Function:		eng_make_String
:Pattern:		engMakeString[string_]
:Arguments:		{string}
:ArgumentTypes:	{UTF16String}
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
:Function:		eng_set
:Pattern:		engSet[name_, handle_]
:Arguments:		{name, handle}
:ArgumentTypes:	{String, Integer32}
:ReturnType:	Manual
:End:

:Evaluate:		End[]
