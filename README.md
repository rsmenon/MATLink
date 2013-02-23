#_MATLink_

_MATLink_ is a [_Mathematica_](http://www.wolfram.com/mathematica/) application that allows the user to communicate data between _Mathematica_ and [MATLAB](http://www.mathworks.com/products/matlab/), as well as execute MATLAB code and seamslesly call MATLAB functions from within _Mathematica_.
It uses [_MathLink_](http://reference.wolfram.com/mathematica/tutorial/MathLinkAndExternalProgramCommunicationOverview.html) to communicate between _Mathematica_ and MATLAB (via the [MATLAB Engine library](http://www.mathworks.com/help/matlab/matlab_external/using-matlab-engine.html)).

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

To define a custom function for the current session and use it, use `MScript` to save it to a file (remember to use the same filename as the function) and then use `MFunction["function_name"]`, where `function_name` is the name of your function file.

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
In MATLAB, one can define functions to have completely different behaviour based on the number of _output_ arguments for the same set of input arguments. This is at odds with the behaviour in _Mathematica_ (and in functional programming languages in general), where a function's behaviour is determined solely by its inputs. To bridge this divide, `MFunction` offers the functionality to use the multiple output form of MATLAB functions, but the number of outputs must be set explicitly when defining the function.

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



##Known issues

###Multiple instances of MATLAB

On OS X, if a MATLAB background process has already been started by _MATLink_, it will not be possible to launch another instance of MATLAB by clicking on its icon.  As a workaround, either start MATLAB before you call `OpenMATLAB[]`or start MATLAB from the terminal as

```bash
open -n /Applications/MATLAB_R2012b.app
```
You can also open it by directly executing the binary from the command line:

```bash
 /Applications/MATLAB_R2012b.app/bin/matlab
```

###`MGet`ting custom classes

Do not use `MGet` on custom classes, or built-in ones such as `MException`.  This will crash the MATLAB process because of a bug in the MATLAB Engine interface on OS X.

---
<sub>_Mathematica_ is a registered trademark of Wolfram Research, Inc. and MATLAB is a registered trademark of The MathWorks, Inc.</sub>
