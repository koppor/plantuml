#!/bin/sh
sed -i "s/# plantuml.*/# plantuml/" README.md
pandoc README.md --pdf-engine=lualatex -o plantuml.pdf
ctanify --notds plantuml.sty plantuml.lua plantuml.pdf README.md CHANGELOG.md "example-*.tex"
