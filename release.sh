#!/bin/sh
# remove shields.io badge
sed -i "s/# plantuml.*/# plantuml/" README.md

# generate plantuml.pdf based on README.md based on pandoc 2.x
pandoc README.md --pdf-engine=lualatex -o plantuml.pdf

# Keep first paragraph of README.md only
# Hint for multiline matching from https://unix.stackexchange.com/a/369899/18033
# We have to use tmp.md, because of file locking on CircleCI
cat README.md | awk 1 ORS=__ABC__ | sed -e "s/__ABC__## Preconditions.*//" | awk 1 RS=__ABC__ > tmp.md && mv tmp.md README.md

# Prepare for CTAN
ctanify --notds plantuml.sty plantuml.lua plantuml.pdf README.md CHANGELOG.md "example-*.tex"
