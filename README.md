#_MATLink_

_MATLink_ is a [_Mathematica_](http://www.wolfram.com/mathematica/) application that allows the user to communicate data between _Mathematica_ and [MATLAB](http://www.mathworks.com/products/matlab/), as well as execute MATLAB code and seamslesly call MATLAB functions from within _Mathematica_.
It uses [_MathLink_](http://reference.wolfram.com/mathematica/tutorial/MathLinkAndExternalProgramCommunicationOverview.html) to communicate between _Mathematica_ and MATLAB (via the [MATLAB Engine library](http://www.mathworks.com/help/matlab/matlab_external/using-matlab-engine.html)).

##System requirements

MATLink is compatible with Mathematica 8 or later and MATLAB R2011b or later.  

On Linux systems, the C shell `csh` must be installed at `/bin/csh` [for MATLAB Engine applications to work](http://www.mathworks.com/help/matlab/matlab_external/using-matlab-engine.html).  Also on Linux, very old versions of gcc can't be used to compile MATLink.  Please check if your compiler is supported by the version of MATLAB you have.  [For MATLAB R2013a it is gcc 4.4.](http://www.mathworks.com/support/compilers/R2013a/index.html?sec=glnxa64)

##Installation
To be able to use _MATLink_, you will need to install it to a location in _Mathematica_'s `$Path`. You can follow one of the three ways below (replace `$UserBaseDirectory` with whatever is shown when you evaluate it in _Mathematica_):

 - Download the [zip file](https://github.com/rsmenon/MATLink/archive/develop.zip) and extract the contents to `$UserBaseDirectory/Applications/MATLink/`.
 - Clone this repository using `git`:

	``` bash
	git clone https://github.com/rsmenon/MATLink.git $UserBaseDirectory/Applications/MATLink
	```
 - Install from within _Mathematica_ using Leonid Shifrin's [ProjectInstaller](https://github.com/lshifr/ProjectInstaller) package:

	```ruby
	ProjectInstall[URL["https://github.com/rsmenon/MATLink/archive/develop.zip"]]
	```

Some further setup may be necessary to let MATLink find MATLAB:

 - On Windows, this is the standard procedure that is necessary to run MATLAB Engine applications:  1. First, add MATLAB's `bin/win64` (`bin/win32` for 32-bit versions) directory to the system `PATH`.  To do this, follow the instructions [here](http://www.mathworks.com/support/solutions/en/data/1-15ZLK/index.html).  2. Now register the default MATLAB version by running the `regmatlabserver` command from within MATLAB.  On most Windows systems it will be necessary to run MATLAB as administrator for the `regmatlabserver` command to work, but this step needs to be done only once.
 - On OS X, navigate to the `MATLink/Engine/bin/MacOSX64` directory, edit the file `mengine.sh` and set the path to the MATLAB app bundle.
 - On Linux, both MATLAB and Mathematica must be in the system `PATH`.  Then MATLink will be able to automatically compile its binary component (a C++ compiler needs to be installed).

##Quick start guide
###Starting MATLAB
After installing the application, load it using ``Needs["MATLink`"]`` and execute `OpenMATLAB[]`. This will launch an instance of MATLAB with which you can now communicate.

###Executing MATLAB code
Using the `MEvaluate` command, it is possible to execute arbitrary MATLAB code. Simply enter the code as strings and pass it to `MEvaluate`. Note that any output that would be displayed in MATLAB's command window will also be displayed in _Mathematica_, so remember to suppress output with semicolons.

As a simple example, consider the following MATLAB code (modified from the example [here](http://www.mathworks.com/help/matlab/ref/for.html)):

```matlab
k = 4;
hilbert = zeros(k,k);      % Preallocate matrix

for m = 1:k
    for n = 1:k
        hilbert(m,n) = 1/(m+n -1);
    end
end
```

One can evaluate this from within _Mathematica_ as:

```ruby
MEvaluate["
	k = 4;
	hilbert = zeros(k,k);      % Preallocate matrix

	for m = 1:k
		for n = 1:k
			hilbert(m,n) = 1/(m+n -1);
		end
	end
"]
```

<sub>(Note: The indentation is only for clarity; MATLAB ignores stray newlines and whitespace)</sub>

You can verify that the matrix `hilbert` was created by evaluating `MEvaluate["whos hilbert"]`.

###Transferring variables
The functions `MSet` and `MGet` allow the user to transfer variables to and from the MATLAB workspace. The variable name is always passed as a string. Continuing the above example, we can import the matrix `hilbert` to the _Mathematica_ workspace:

```ruby
hilbert = MGet["hilbert"];
```

The result is imported as a native _Mathematica_ array, i.e., a list of lists, which can then be used in further computations.

Similarly, one can pass a variable to MATLAB using the `MSet` function. We shall now pass the imported variable `hilbert` back to MATLAB and store it in a new variable called `gilbert`:

```ruby
MSet["gilbert", hilbert];
```

You can now verify that the imported matrix was indeed passed back correctly by evaluating `MEvaluate["isequal(gilbert,hilbert)"]`

###Saving and executing arbitrary MATLAB code as scripts
Often one wishes to reuse code found online, either on the MathWorks [File Exchange](http://www.mathworks.com/matlabcentral/fileexchange/) or elsewhere and execute it as a script (with side-effects). The function `MScript` makes it easy to do this. In the following example, we define a script (not a function) called `timing.m` that does some computations and displays the timing

```ruby
t = MScript["timing",
	"tic;
	for i=1:100
		eig(randn(100));
	end
	toc"
]
```
<sub>(Note: The indentation is only for clarity; MATLAB ignores stray newlines and whitespace)</sub>

You can now run the above script anytime, several times within the current session, by simply evaluating `MEvaluate[t]` (assuming its value has not been cleared) or `MEvaluate[MScript["timing"]]`.

> **Also see:** "Overwriting session scripts" under the **Advanded usage** section.


###Defining and using MATLAB functions
You can natively call MATLAB functions already on its path using the `MFunction` command, which allows the user to extend the functionality of MATLAB. As an example, we'll define and use the `magic` function from MATLAB, which is not available in _Mathematica_:

```ruby
magic = MFunction["magic"];
magic[4] // MatrixForm
```

To define a custom function for the current session and use it, use `MScript` to save it to a file (remember to use the same filename as the function) and then use `MFunction["function_name"]`, where `function_name` is the name of your function file. As a simple example:

```ruby
MScript["add2", "
	function out = add2(x,y)
  	 	out = x + y;
  	end
 "];
MFunction["add2"][3, 4]
(* Output: 7. *)
```

> **Also see:** "Handling functions with multiple outputs (and no outputs)" under the **Advanded usage** section.

###Closing MATLAB
To completely disconnect from the MATLAB engine, call `DisconnectMATLAB[]`. This will also delete all scripts that were defined for the current _MATLink_ session.

##Advanced usage

###Properly starting and closing MATLAB
There are in fact, four functions that provide different functionality associated with starting and closing MATLAB:

 - `ConnectMATLAB[]` establishes a _MathLink_ connection to the low level C functions and the MATLAB engine, sets various session specific variables, but does not launch MATLAB.
 - `OpenMATLAB[]` launches the MATLAB application in the background.
 - `CloseMATLAB[]` closes the MATLAB application, but keeps the connection to the MATLAB engine open.
 - `DisconnectMATLAB[]` closes the MATLAB engine, terminates the _MathLink_ connection and clears session variables and temporary folders.

For convenience, directly calling `OpenMATLAB[]` automatically calls `ConnectMATLAB[]`, but it is possible to only call `ConnectMATLAB[]` without actually opening MATLAB. One can then call `OpenMATLAB[]` and `CloseMATLAB[]` several times (assuming other external factors such as kernel/front end crashes haven't terminated the _MathLink_ connection) and it is still considered to be the same "session".

The scripts defined during the session are saved in in a session specific folder in the user's `$TemporaryDirectory`. This directory and its contents are removed only when `DisconectMATLAB[]` is called. Hence it is always preferable (and recommended) to call `DisconnectMATLAB[]` when done with using _MATLink_. If the application terminates due to forced kernel quits or crashes, the temporary directory remains, and a new one is created for the next session.

Over prolonged use, these session specific directories can accumulate (since _Mathematica_ crashes are inevitable), if one is not meticulous about regularly clearing their `$TemporaryDirectory`. In such cases, the user can load the package as follows, before connecting to MATLAB:

```ruby
Needs["MATLink`"]
MATLink`Developer`CleanupTemporaryDirectories[]
```

###Overwriting session scripts
By default, it is not possible to overwrite a script defined in the current session using `MScript`. Attempting to do so will produce the following error:

```
MScript::owrt: An MScript by that name already exists. Use "Overwrite" -> True to overwrite.
```

If it is necessary to overwrite the script (to fix typos or change parameters), use the option `"Overwrite" -> True` in `MScript`.

###Handling functions with multiple outputs (and no outputs)
In MATLAB, one can define functions to have completely different behaviour based on the number of _output_ arguments for the same set of input arguments. This is at odds with the behaviour in _Mathematica_ (and in functional programming languages in general), where a function's behaviour is determined solely by its inputs. To bridge this divide, `MFun  ction` offers the functionality to use the multiple output form of MATLAB functions, but the number of outputs must be set explicitly when defining the function.

As an example, consider the `eig` function in MATLAB, which has a single output form that returns only the eigenvalues as a vector, and the two output form which returns both the eigenvalues and the eigenvectors as a matrices. We associate a different symbol in _Mathematica_ for each of those two cases as:

```ruby
eig = MFunction["eig"];
eigsystem = MFunction["eig", "OutputArguments" -> 2];
```

This way, each function in _Mathematica_ still does only one thing for the same set of inputs, but also allows the user to make full use of MATLAB's versatility.

Sometimes, one does not desire an output from a function that produces other side-effects. For example, plotting commands in MATLAB produce a plot, but also return the handle number if an output is requested. To supress the output, one can use the `"Output" -> False` argument. The following example, uses data from _Mathematica_ and creates a MATLAB plot — all from within _Mathematica_:

```ruby
imagesc = MFunction["imagesc", "Output" -> False];
data = Import["ExampleData/ozonemap.hdf", {"Datasets", "TOTAL_OZONE"}][[20 ;;, All]];
imagesc[data];
```
![](http://i.stack.imgur.com/UxUkbm.png)

##Supported MATLAB data types

The following data types can be transferred in both directions:

 - double precision numerical arrays (including multidimensional)
 - double precision sparse matrices
 - logical arrays (including multidimensional)
 - sparse logical matrices
 - strings (i.e. char arrays of dimension `[1 n]`)
 - cells (including multidimensional)
 - structs (only with size `[1 1]`)


The following can only be transferred from MATLAB to Mathematica:

 - numerical arrays with the following types: single, int16, int32
 - structs with any number of elements 


----

##Reference documentation

Each public function _MATLink_ is briefly documented in this section.

####`OpenMATLAB`

`OpenMATLAB[]` will start the MATLAB process and connect to it.  Use `CloseMATlAB[]` to close the running MATLAB session.

**See also:** `CloseMATLAB`

####`CloseMATLAB`

`CloseMATLAB[]` closes an open MATLAB session.

**See also:** `OpenMATLAB`

####`MEvaluate`

`MEvaluate[command]` evaluates `command` in MATLAB and returns the output as text.

**Examples:**

```
In[]:= MEvaluate["1+1"]
Out[]=
      ans =

           2
```

**Possible issues:**

 * `MEvaluate` performance suffers if the output is not suppressed in MATLAB code.  If you do not need to see the output of `MEvaluate`, use `MEvaluate["command;"]` instead of `MEvaluate["command"];`.

 * The output length of `MEvaluate` is limited to approximatey 100,000 characters.  The rest will be truncated.
 
**See also:** `MScript`


####`MGet`

`MGet["x"]` will return the value of the variable `x` from the MATLAB workspace.  Data structures are translated into a Mathematica-compatible format.

**Examples:**

```
In[]:= MEvaluate["x = 1:10;"]

In[]:= MGet["x"]
Out[]= {1., 2., 3., 4., 5., 6., 7., 8., 9., 10.}
```

`MGet` is `Listable`:

```
In[]:= MEvaluate["[v d] = eig(rand(5));"]

In[]:= {v, d} = MGet[{"v", "d"}];
```

**Possible issues:**

 * MATLAB works with floating point values by default. Even array indices are floating point.  Such values need to be explicitly `Round`ed in Mathematica before they can be used as indices again.  Example:
 
```
MEvaluate["s = size(zeros(3,4));"]
s = MGet["s"]

(* ==> {3., 4.} *)
```

 * Do not attempt to use `MGet` on objects (`classdef` objects) or data structures which contain objects.  This will crash MATLAB because of a MATLAB bug.  See the "Known issues" section for additional details.

**See also:** `MSet`


####`MSet`

`MSet["x", value]` will assign `value` to variable `x` in the MATLAB workspace.  `value` must be in the same format as would be returned by `MGet`.

**Examples:**

```
In[]:= MSet["a", {1,2,3}]
       MEvaluate["a"]
       
Out[]= a =

          1     2     3
          
In[]:= MSet["b", {"one" -> {1, 2, 3}, "two" -> {4, "five"}}]
       MEvaluate["b"]
       
Out[]= b =

         one: [1 2 3]
         two: {[4]  'five'}
```

To force a list to be sent as a cell, wrap it in the `MCell` head:

```
In[]:= MSet["a", MCell[{1, 2, 3}]]
       MEvaluate["a"]
       
Out[]= a =

          [1] [2] [3]
```

**See also:** `MGet`


####`MFunction`

`MFunction["func"]` represents the MATLAB function `func`.  It can be called directly from within Mathematica.

`MFunction["func", "body"]` creates a new `.m` file with the contents `body` and returns `MFunction["func"]`.  This is analogous to how `MScript` works.

By default, `func` is expected to have a single output.  To call it with no output arguments, use `MFunction["func", "Output" -> False]`.  To specify more than one output argument, use the `"OutputArguments"` option: `MFunction["func", "OutputArguments" -> 2]`.

When creating new functions using the syntax `MFunction["func", "body"]`, `MFunction` does not overwrite exsiting `.m` files.  To force overwriting an existing `.m` file, use the option `"Overwrite" -> True`. See `MScript` for more details.

**Examples:**

Wrap a MATLAB function to make it directly callable from Mathematica:

```
In[]:= eig = MFunction["eig"]
Out[]= MFunction["eig"]

In[]:= eig[{{1, 2}, {3, 4}}]
Out[]= {{-0.372281}, {5.37228}}
```

Use two output arguments instead of one:

```
In[]:= eig = MFunction["eig", "OutputArguments" -> 2]
Out[]= MFunction["eig", "OutputArguments" -> 2]

In[]:= eig[{{1, 2}, {3, 4}}]
Out[]= {{{-0.824565, -0.415974}, {0.565767, -0.909377}}, 
          {{-0.372281, 0.}, {0., 5.37228}}}
```

Write a custom function:

```
In[]:= add = MFunction["add", "
  function res = add(x,y)
  res = x+y
  end"]

Out[]= MFunction["add"]

In[]:= add[3, 4]
Out[]= 7.
```

**Possible issues:**

Bye default `MFunction` assumes a single output argument.  This causes errors in some MATLAB functions:

```
In[]:= MFunction["disp"]["Hello"]

MATLink::errx: Error using disp
Too many output arguments.

Out[]= $Failed
```

Use `"Output" -> False` to indicate that the function cannot have any output arguments: `MFunction["disp", "Output" -> False]["Hello"]`

**See also:** `MScript`.

####`MScript`

`MScript["scriptname", "commands"]` will create a MATLAB script with the contents `commands`.  It returns `MScript["scriptname"]` which can be evaluated using `MEvaluate`.

If a script with the specified name already exists, `MScript` will issue a message and it will not overwrite it by default.  To force overwriting the existing script, use `MScript["scriptname", "commands", "Overwrite" -> True]`.

**Examples:**

```
In[]:= hello = MScript["hello", "disp('Hello world!')"]
Out[]= MScript["hello"]

In[]:= MEvaluate[hello]
Out[]=
"Hello world!"
```

**See also:** `MFunction`, `MEvaluate`

####`CommandWindow`

`CommandWindow["Show"]` will show the MATLAB command window.  When an evaluation is not in progress, this window can be used to input MATLAB commands independently of _MATLink_.   Use `CommandWindow["Hide"]` to hide the window again. 

This functionanilty is only available on Windows.

---

##Known issues and limitations

###Large array support

At the moment, only arrays with less than `2^31-1` elements are supported.  Note that this is true for matrices and multidimensional arrays as well: the _total number_ of matrix elements may not excede `2^31-1` even if the matrix has fewer rows and columns than this.  As an example, the largest supported square matrix can be of size 46341 by 46341.

As a reference point, a double precision array with the maximum number of allowed elements would take up 16 GB of memory, so this limit should be more than sufficient for most applications.

###Inf and NaN

Inf and Nan are not supported at the moment.  The values returned to Mathematica are not safe to use: operations on them give unpredictable results.

###Multiple instances of MATLAB on OS X

On OS X, if a MATLAB background process has already been started by _MATLink_, it will not be possible to launch another instance of MATLAB by clicking on its icon.  As a workaround, either start MATLAB before you call `OpenMATLAB[]`or start MATLAB from the terminal as

```bash
open -n /Applications/MATLAB_R2013a.app
```
You can also open it by directly executing the binary from the command line:

```bash
 /Applications/MATLAB_R2013a.app/bin/matlab
```

###`MGet`ting objects

Do not use `MGet` on MATLAB objects, or data structures that contain custom classes as elements.  On OS X and Unix this will crash the MATLAB process because of a bug in the MATLAB Engine interface.

Example:

```
m = containers.Map('a',1);
s = struct('a',1, 'b',m);
```

`MGet["m"]` will crash MATLAB because `m` is an object.  `MGet["s"]` will crash because `s` contains an object.

Note: This will be fixed by the switch to the MEX interface.

###Reading HDF5 based `.mat` files

All the limitations of the [MATLAB Engine interface](http://www.mathworks.com/help/matlab/matlab_external/using-matlab-engine.html) apply to MATLink.  The most noticeable of these is that HFD5 based `.mat` files cannot be read.  Quoting the [MATLAB documentation](http://www.mathworks.com/help/matlab/matlab_external/using-matlab-engine.html),

> The MATLAB engine cannot read MAT-files in a format based on HDF5. These are MAT-files saved using the -v7.3 option of the save function or opened using the w7.3 mode argument to the C or Fortran matOpen function.

As of R2013a, MATLAB does not save `.mat` files in this format by default, unless its settings are changed.

Note: This will be fixed by the switch to the MEX interface.


###Unicode support

`MGet` and `MSet` do support Unicode strings, and will preserve Unicode characters.  However, `MEvaluate` will not preserve unicode characters in its output.  `MEvaluate` should handle Unicode input correctly.  If you discover a situation where it does not, please report it.

The reason unicode output needed to be disabled for `MEvaluate` is that MATLAB's C API is unpredictable and may not produce correct unicode output depending on version and operating system.

Example:

```
In[]:= MEvaluate["s='Paul Erdős'"] (* Unicode input *)

Out[]= 

s =

Paul Erd!s

In[]:= MGet["s"]
Out[]= Paul Erdős

```

In `MEvaluate`'s output Unicode in mangled, however, `MGet` trasfers it correctly.

A workaround is using `evalc`.  This is not used in MATLink because of unsolved [issue #29](https://github.com/rsmenon/MATLink/issues/29).


---

<sub>_Mathematica_ is a registered trademark of Wolfram Research, Inc. and MATLAB is a registered trademark of The MathWorks, Inc.</sub>
