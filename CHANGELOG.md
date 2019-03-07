# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [unreleased]

## Added

- Added `example-component-diagram.tex`. Refs [#2](https://github.com/latextemplates/plantuml/issues/9).

## [0.2.3] - 2018-06-04

## Added

- Add `release.sh` to CTAN upload-

## Removed

- Removed `\usepackage{aeguill}` as 1) PlantUML seems not to rely on it any more and 2) [it is obsolete and should not be used anymore](https://tex.stackexchange.com/a/5901/9075).

## [0.2.2] - 2018-03-22

## Changed

- Added version number in generated `plantuml.pdf`.
- Do not strip down `README.md` for CTAN anymore and provide "*.png" for generation of `plantuml.pdf`.

## [0.2.1] - 2018-03-21

### Fixed

- Added short version of `README.md` to CTAN distribution again, because of [CTAN rules](https://mirror.informatik.hs-fulda.de/tex-archive/help/ctan/CTAN-upload-addendum.html#readme).

## [0.2.0] - 2018-03-20

### Changed

- `README.md` is not distributed to CTAN anymore, because `plantuml.pdf` is distributed to follow latex software conventions to name the manual according to the name of the package.
  `plantuml.pdf` generated out of `README.md`.
- Removed call to `pdfcrop` is not necessary anymore, because inkscape is called without `-D` for svg convertion.

### Added

- `release.sh` for creating a release.

## 0.1.0 - 2018-03-08

Initial public release

[unreleased]: https://github.com/latextemplates/plantuml/compare/0.2.3...HEAD
[0.2.3]: https://github.com/latextemplates/plantuml/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/latextemplates/plantuml/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/latextemplates/plantuml/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/latextemplates/plantuml/compare/0.1.0...0.2.0
