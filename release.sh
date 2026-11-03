#!/bin/sh
# The CI checkout has no tags, so take the version from \ProvidesPackage.
TAG=$(sed -n 's/.* v\([0-9.]*\)$/\1/p' plantuml.sty | head -1)

# remove shields.io badge
sed -i "s/# plantuml.*/# plantuml\n\nVersion $TAG/" README.md

# The README images are SVG (sharp/vector). pandoc converts SVG to PDF for the
# LaTeX engine via rsvg-convert, which the build image does not ship by default.
command -v rsvg-convert >/dev/null 2>&1 || apt-get update -qq && apt-get install -y -qq librsvg2-bin

# generate plantuml.pdf based on README.md based on pandoc 2.x
pandoc README.md --pdf-engine=lualatex -o plantuml.pdf

# Prepare for CTAN
ctanify --notds plantuml.sty plantuml.lua plantuml.pdf README.md CHANGELOG.md release.sh "example-*.tex" "example-*.svg" "example-*.puml"
