#!/bin/sh
TAG=`git describe --abbrev=0 --tags`

# remove shields.io badge
sed -i "s/# plantuml.*/# plantuml\n\nVersion $TAG/" README.md

# generate plantuml.pdf based on README.md based on pandoc 2.x
pandoc README.md --pdf-engine=lualatex -o plantuml.pdf

# Prepare for CTAN
ctanify --notds plantuml.sty plantuml.lua plantuml.pdf README.md CHANGELOG.md release.sh "example-*.tex" "example-*.png"
