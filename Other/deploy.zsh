#!/usr/local/bin/zsh
#Place this in the MATLink/ folder in the dev setup
#README.md is not copied since the contents are very different
setopt EXTENDED_GLOB
MATLINKDIR=~/Library/Mathematica/Applications/MATLink/

gcp --preserve=mode --parents $(dirname $0)/**/**~(*.dSYM/*|*/mengine.txt|*.zsh|LICENSE.txt) $MATLINKDIR
