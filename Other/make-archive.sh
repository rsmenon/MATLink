#!/bin/sh

curl -OL https://github.com/rsmenon/MATLink/archive/latest.zip
unzip latest.zip
mv MATLink-latest MATLink
rm MATLink.zip
zip -r MATLink.zip MATLink -x "*.DS_Store"
rm -r MATLink latest.zip
