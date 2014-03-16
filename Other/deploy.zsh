#!/usr/local/bin/zsh
#Place this in the MATLink/ folder in the dev setup
#README.md is not copied since the contents are very different
setopt EXTENDED_GLOB
MATLINKDIR=~/Library/Mathematica/Applications/MATLink/

rsync -a --exclude="/.idea" --exclude="/.git" --exclude="/Test" --exclude="*.nb" --exclude="*.zsh" --exclude="*.iml" --exclude=".gitignore" --exclude="*.dSYM" --exclude="*.txt" --exclude=".DS_Store" $(dirname $0) $MATLINKDIR
