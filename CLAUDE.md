# CLAUDE.md

Guidance for working in this repository.

This is the `plantuml` LaTeX package (CTAN): a LuaLaTeX/pdfLaTeX package
(`plantuml.sty` + `plantuml.lua`) that embeds PlantUML diagrams by shelling out
to `plantuml.jar`. It requires `-shell-escape` and the `PLANTUML_JAR`
environment variable (see `README.md`).

## Updating PlantUML

CI does **not** pin a PlantUML version. Both `.github/workflows/check.yml` and
`.github/workflows/release.yml` resolve the latest release at run time:

```sh
gh api repos/plantuml/plantuml/releases/latest --jq '.tag_name'
```

and download `plantuml-<version>.jar` via `ethanjli/cached-download-action`. The
download cache is keyed on the resolved version, so it refreshes automatically
whenever PlantUML publishes a new release — there is nothing to bump by hand.

- **`check.yml`** compiles the examples with `-output-directory` against the
  latest PlantUML, so we notice when a new PlantUML release breaks the package.
- **`release.yml`** builds the CTAN package and GitHub Pages with the same
  latest jar.

To **pin** a specific version instead, replace the "Resolve latest PlantUML
version" step with a fixed value, e.g.:

```yaml
      - name: Resolve PlantUML version
        id: plantuml-version
        run: echo "version=1.2025.1" >> "$GITHUB_OUTPUT"
```

Locally, point `PLANTUML_JAR` at any jar; grab the latest from
<https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar>.

## Testing changes

Compile the examples with `-shell-escape` (optionally adding `-output-directory`)
using `lualatex` or `pdflatex`. Run the LaTeX toolchain inside Docker rather than
on the host.
