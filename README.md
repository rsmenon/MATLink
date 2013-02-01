MATLink
=======

Communicate with MATLAB from Mathematica

This package makes it possible to seamslessly call MATLAB functions from Mathematica as well as transfer variables between the MATLAB and Mathematica workspaces.

Known issues
============

On OS X, if a MATLAB background process has already been started by MATLink, it will not be possible to launch another instance of MATLAB by standard means.  As a workaround, either start MATLAB before you call `OpenMATLAB[]` from MATLink or start MATLAB from the command line using the `open -n` command.
