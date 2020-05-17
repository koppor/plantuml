#!/bin/sh
TAG=`git describe --abbrev=0 --tags`

# remove shields.io badge
sed -i "s/# plant-uml.*/# plant-uml\n\nVersion $TAG/" README.md

# generate plant-uml.pdf based on README.md based on pandoc 2.x
pandoc README.md --pdf-engine=lualatex -o plant-uml.pdf

# Prepare for CTAN
ctanify --notds plant-uml.sty plant-uml.lua plant-uml.pdf README.md CHANGELOG.md release.sh "example-*.tex" "example-*.png"
