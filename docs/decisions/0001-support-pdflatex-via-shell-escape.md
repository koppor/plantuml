---
status: accepted
date: 2026-06-25
decision-makers: Oliver Kopp
consulted:
informed:
---

# Support pdfLaTeX by driving PlantUML directly via shell escape

## Context and Problem Statement

The package historically worked with LuaLaTeX only.
There, the `plantuml` environment shells out through `plantuml.lua`
(`io.popen` / `os.getenv` / `lfs`) to run `plantuml.jar`.
Under pdfLaTeX the environment was a stub that printed
*"plantuml only works with lualatex"* ([#1]).

How should pdfLaTeX run PlantUML so that `pdflatex -shell-escape file.tex`
produces the diagrams — ideally with the same single-command workflow and the
same caching that the LuaLaTeX path already offers?

## Decision Drivers

* **Single-command workflow.** `pdflatex -shell-escape file.tex` should just
  work, exactly like LuaLaTeX — no extra build step.
* **Parity with the LuaLaTeX path.** Same `plantuml.jar` invocation, same
  generated files, and the same *skip-if-unchanged* caching that fixed the
  `latexmk` rebuild loop ([#49]).
* **Cross-platform** (Linux/macOS/Windows). Windows is an explicitly supported
  target of the package.
* **Minimal new dependencies**, so installation from CTAN stays easy.
* **Support the flagship `output=latex` mode**, where PlantUML's TikZ output is
  `\input` *inline* into the document (not a separate image/PDF).

## Considered Options

* **Direct shell escape (`\write18`)** from the package, mirroring the LuaLaTeX path
* **`hvextern`** ([CTAN](https://ctan.org/pkg/hvextern))
* **`pythontex`** ([CTAN](https://ctan.org/pkg/pythontex)) — options 1 & 2 of [#1]
* **`bashful`** ([CTAN](https://ctan.org/pkg/bashful)) — option 4 of [#1]
* **`checklistings`** ([CTAN](https://ctan.org/pkg/checklistings)) — option 3 of [#1]

The `download` package mentioned in [#1] only fetches files and does not execute
PlantUML, so it is not a candidate. `hvextern` (option 5) is the most actively
maintained of the third-party options and is therefore weighed explicitly below.

## Decision Outcome

Chosen option: **Direct shell escape (`\write18`)**, because it is the only
option that satisfies *every* decision driver. It reuses the exact `plantuml.jar`
command, generated-file layout, and MD5 caching of the LuaLaTeX path; keeps the
one-command workflow; adds no heavyweight dependencies; works cross-platform; and
natively supports the inline-TikZ `output=latex` mode. In effect, the pdfTeX path
becomes the `\write18` / `pdftexcmds` twin of `plantuml.lua`.

### Consequences

* Good, because pdfLaTeX and LuaLaTeX now behave identically (same command, same
  files, same caching) — one mental model and one set of examples for both engines.
* Good, because no new CTAN dependencies are pulled in: only `pdftexcmds`
  (already required) and `iftex` are used; `PLANTUML_JAR` is read cross-platform
  via `kpsewhich --var-value=PLANTUML_JAR`.
* Good, because the source-MD5 cache avoids re-running PlantUML on every LaTeX
  pass, preventing the `latexmk` rebuild loop on the pdfLaTeX side as well.
* Neutral, because the orchestration (run command + cache) now exists twice, in
  Lua and in TeX. The duplicated surface is small, and the TeX side adds no
  third-party package whose breakage we would have to track.
* Neutral, because full `-shell-escape` is required — but that was already
  mandatory for the LuaLaTeX path.

### Confirmation

A CI job compiles the example documents with `pdflatex -shell-escape` (in
addition to the existing `lualatex` jobs); the build fails if a diagram does not
render. Manual confirmation: compiling an example twice prints
`unchanged; skipping PlantUML` on the second run (cache hit).

## Pros and Cons of the Options

### Direct shell escape (`\write18`)

The package writes the diagram source to `…-plantuml.txt`, then runs
`java -jar "$PLANTUML_JAR" … -pipe -t… < src > tgt` via `\immediate\write18`,
reads `PLANTUML_JAR` via `kpsewhich --var-value`, and hashes the source with
`\pdf@filemdfivesum` to decide whether a re-run is needed.

* Good, because byte-for-byte parity with `plantuml.lua` (same command, same outputs).
* Good, because no third-party LaTeX package dependency, and cross-platform.
* Good, because it supports inline-TikZ `output=latex` as well as the image modes.
* Bad, because it duplicates a little orchestration logic across Lua and TeX.

### hvextern

Herbert Voß, v0.42 (2025-05-14) — the most actively maintained of the listed
third-party options. Writes external source files and compiles them, via shell
escape, into **separate** PDF/PNG/text outputs that are then included.

* Good, because actively maintained and purpose-built for "run an external tool
  and include the result".
* Bad, because it produces *separate* externals; it does not fit the flagship
  `output=latex` mode, where PlantUML's TikZ is `\input` inline.
* Bad, because it would still require shell escape and `PLANTUML_JAR` handling,
  while adding a dependency and a model that diverges from the LuaLaTeX path.

### pythontex

Geoffrey M. Poore, v0.19 (2026) — very actively maintained; executes embedded
code (Python/Bash/…) and re-runs it only when changed.

* Good, because mature, maintained, and has built-in "run only when changed".
* Bad, because it requires a **separate `pythontex` run** between LaTeX passes,
  breaking the single-command workflow that LuaLaTeX provides.
* Bad, because it pulls in a Python toolchain; and [#1] itself notes the
  difficulty of passing LaTeX counters into the executed bash code.

### bashful

Yossi Gil, v0.93 — last updated 2012; runs bash scripts via shell escape.

* Bad, because it is Unix/bash-only ("not, without modification, in a Windows
  environment"), failing the cross-platform driver.
* Bad, because it is effectively unmaintained (no release since 2012).

### checklistings

Generates a `checklistings.sh` that the **user** has to run with an external tool.

* Bad, because it breaks the single-command workflow with a manual external step.

## More Information

* Issue [#1] — *Support pdflatex*.
* The LuaLaTeX implementation this mirrors: `plantuml.lua` and the `\ifluatex`
  branch of `plantuml.sty`.
* The caching mirrors [#49], which stopped `latexmk` from looping by running
  PlantUML only when the source changed.

[#1]: https://github.com/koppor/plantuml/issues/1
[#49]: https://github.com/koppor/plantuml/pull/49
