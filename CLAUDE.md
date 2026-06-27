# CLAUDE.md

Guidance for working in this repository.

This is the `plantuml` LaTeX package (CTAN): a LuaLaTeX/pdfLaTeX package
(`plantuml.sty` + `plantuml.lua`) that embeds PlantUML diagrams by shelling out
to `plantuml.jar`. It requires `-shell-escape` and the `PLANTUML_JAR`
environment variable (see `README.md`).

## Updating PlantUML

CI pins the PlantUML version. Both `.github/workflows/check.yml` and
`.github/workflows/release.yml` download a fixed `plantuml-<version>.jar` via
`ethanjli/cached-download-action` (the cache is keyed on the version, so a bump
fetches the new jar automatically).

To **bump** PlantUML, change the version in the "Set PlantUML version" step:

```yaml
      - name: Set PlantUML version
        id: plantuml-version
        run: echo "version=1.2026.6" >> "$GITHUB_OUTPUT"
```

It appears **once in `check.yml` and twice in `release.yml`** (one per job) —
update all of them to the same value. Pick a version from
<https://github.com/plantuml/plantuml/releases>.

- **`check.yml`** compiles the examples with `-output-directory` (regression test
  for the pinned PlantUML). It also has a `server` job (regression test for #6)
  that renders `example-server--{png,svg}` against a `plantuml/plantuml-server`
  service container with `PLANTUML_JAR` unset; that job uses the server image's
  own (unpinned) PlantUML, not the jar version above.
- **`release.yml`** builds the CTAN package and GitHub Pages with the same jar.

Locally, point `PLANTUML_JAR` at any jar; grab one from
<https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar>.

## Testing changes

Compile the examples with `-shell-escape` (optionally adding `-output-directory`)
using `lualatex` or `pdflatex`. Run the LaTeX toolchain inside Docker rather than
on the host.
