
# Set path to MATLAB and MathLink here:
MATLABDIR   = /Applications/MATLAB_R2012b.app
MATHLINKDIR = /Applications/Mathematica\ 9.app/SystemFiles/Links/MathLink/DeveloperKit

SYS = MacOSX-x86-64
CADDSDIR = $(MATHLINKDIR)/$(SYS)/CompilerAdditions

INCDIRS = -I$(CADDSDIR) -I$(MATLABDIR)/extern/include/
LIBDIRS = -L$(CADDSDIR) -L$(MATLABDIR)/bin/maci64/

MPREP = $(CADDSDIR)/mprep

EXTRA_LIBS = -lstdc++ -framework Foundation -mmacosx-version-min=10.6

CFLAGS = -mmacosx-version-min=10.6 -O

.c.o:
	$(CC) $(CFLAGS) $(INCDIRS) -c $<


all: mEngine

template.c: template.tm
	$(MPREP) template.tm > template.c

mEngine: open.o close.o cmd.o get.o put.o isopen.o mengine.o vis.o main.o template.o
	$(CC) open.o close.o cmd.o get.o put.o isopen.o mengine.o vis.o main.o template.o $(LIBDIRS) -lMLi3 -lmx -leng ${EXTRA_LIBS} -o mEngine

clean:
	rm -rf *.o mEngine template.c
