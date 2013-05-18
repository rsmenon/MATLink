#Troubleshooting MATLink

Before beginning the troubleshooting, check that MATLink has been set up according to the installation instructions on [matlink.org](http://matlink.org)  and that your system meets the necessary requirements.  Here's a short summary for each operating system:

**On Windows**, 

 * MATLAB must have been registered as a COM server by running it as administrator and evaluating `!regmatlabserver`.
 
 * The `bin\win64` directory (or `bin\win32` for 32-bit versions) must be on the `PATH`.
 
**On OS X,**

 * If MATLAB is not installed in a standard location, make sure that the correct location of the MATLAB app bundle is set in the `MATLink/Engine/bin/MacOSX64/mengine.sh` file.
 
 * Make sure that `/bin/csh` is working.
 
**On Linux,**

 * Ensure that both `matlab` and `math` are in the `PATH`.  Also ensure that `matlab` can be launched *from within Mathematica* by evaluating `Import["!matlab -nodesktop -nojvm -r quit", "Text"]` in Mathematica.  Unfortunately Mathematica may sometimes change `PATH`.
 
 * Ensure that you have a recent version of `g++` installed.  Recent versions of MATLAB require gcc version 4.4 or later.  If `g++` is not installed, on Ubuntu, use `apt-get install g++`.
 
 * Ensure that `/bin/csh` is installed and it works.  On Ubuntu, use `apt-get install csh`.
 
 
##`OpenMATLAB[]` hangs on Linux or OS X

This typically indicates that the script `mengine.sh` failed to launch the binary  executable `mengine`.  The most common cause for this is that it cannot find the shared libraries it needs from either Mathematica or MATLAB.  Try launching `mengine.sh` manually from the terminal and see if it complains about missing libraries.

If it is working correctly, you should see a prompt `Create link:`.  At this prompt press enter twice to exit.

On Linux only, if MATLAB has been upgraded to a newer version, it may be necessary to recompile mengine.  Do this by evaluating the following in a fresh kernel:

    Needs["MATLink`"]
    MATLink`Developer`CompileMEngine[]


##Windows: "The program can't start because libmx.dll is missing from your computer"

Make sure you follow the installation instructions and add MATLAB's `bin\win64` (`bin\win32` directory if MATLAB is 32-bit) to the `PATH` environment variable.  These directories are located within MATLAB's installation directory.  A typical location could be

    C:\Program Files\MATLAB\R2013a\bin\win64
    
(depending on where MATLAB is installed)


##Windows: "The application was unable to start correctly"

This error will come up if you are using a 64-bit version of Mathematica with a 32-bit version of MATLAB.  Note that the student version of MATLAB on Windows is 32-bit.

To be able to use a 32-bit MATLAB with a 64-bit Mathematica, evaluate the following:

    Needs["MATLink`"]
    SetOptions[MATLink, "Force32BitEngine" -> True]
    
    
##Linux: "Automatically compiling the MATLink Engine has failed"

Linux binaries of `mengine` are not included in the download package.  MATLink relies on automatic compilation instead. The error indicates that this has failed.

First, make sure that you have a recent version of `g++` installed (gcc 4.4 is required for MATLAB R2013a).

To see what is going wrong during compilation, try compiling `mengine` manually:

 * Open a terminal and navigate to the directory `MATLink/Engine/src`.
 * Run `make -f Makefile.lin64` (or `make -f Makefile.lin32`).

If the errors shown don't give an indication of what is going wrong, send an email to `matlink.m@gmail.com`.


##"Automatically compiling the MATLink Engine from source for 32-bit OS X is not supported"

We do not have access to 32-bit OS X systems, so we can't provide binaries for them.

If you are using such an old system, you will need to compile `mengine` yourself, and place the resulting binary in `MATLink/Engine/bin/MacOSX32/`.  You will also need to provide an `mengine.sh` script that sets `PATH` and `DYLD_LIBRARY_PATH` before launching `mengine`.  Please see the model in `MATLink/Engine/bin/MacOSX64/`.

If you need assistance, send an e-mail to `matlink.m@gmail.com`.

