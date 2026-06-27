-- SPDX-License-Identifier: LPPL-1.3c+

require "lfs"

-- Hex-encode a string. Used to build PlantUML server URLs with the "~h" marker,
-- which lets us avoid the deflate-based PlantUML text encoding (that would need a
-- compression library not available in plain Lua). (#6)
local function plantUmlHexEncode(data)
  return (data:gsub(".", function(c) return string.format("%02x", string.byte(c)) end))
end

-- @param mode directly passed to PlantUML. Recommended: png, svg, pdf (requires Apache Batik to convert svg to pdf)
-- @param iodir directory prefix (with trailing slash) where the generated
--   *-plantuml.* files live. Empty unless lualatex runs with -output-directory:
--   LaTeX redirects its writes there, but this script (a shell-escape
--   subprocess) runs in the real working directory, so it must reach in
--   explicitly. See plantuml.sty for how the prefix is determined (#27).
-- @param server PlantUML server base URL, e.g. https://www.plantuml.com/plantuml.
--   When set (package option `server`, or the PLANTUML_SERVER environment
--   variable as a fallback), png and svg diagrams are fetched from the server via
--   curl instead of running plantuml.jar locally. The server cannot produce
--   latex/TikZ output, so latex always uses the local jar. (#6)
-- @return the content hash of the diagram (so plantuml.sty can include the
--   hash-named output file), or nil if the diagram could not be generated.
function convertPlantUmlToTikz(jobname, mode, iodir, server)
  iodir = iodir or ""
  server = server or ""
  if server == "" then server = os.getenv("PLANTUML_SERVER") or "" end
  while server:sub(-1) == "/" do server = server:sub(1, -2) end
  local useServer = (server ~= "") and (mode == "png" or mode == "svg")

  local plantUmlSourceFilename = iodir .. jobname .. "-plantuml.txt"

  if not (lfs.attributes(plantUmlSourceFilename)) then
    texio.write_nl("Source " .. plantUmlSourceFilename .. " does not exist.")
    return nil
  end

  -- Read the source and content-address the output by its hash, minted/memoize
  -- style: identical (or reordered) diagrams reuse the cached file and PlantUML
  -- is run only when no matching output exists yet. (#2)
  local sourceHandle = io.open(plantUmlSourceFilename, "rb")
  if not sourceHandle then
    texio.write_nl("Error: Could not open source file for reading.")
    return nil
  end
  local sourceContent = sourceHandle:read("*a")
  io.close(sourceHandle)

  local md5lib = md5 or require("md5")
  -- uppercase to match pdfTeX's \pdf@filemdfivesum, so both engines name the
  -- cache file identically for the same diagram (#2).
  local hash = md5lib.sumhexa(sourceContent):upper()
  local ext = (mode == "latex") and "tex" or mode
  local plantUmlTargetFilename = iodir .. "plantuml-" .. hash .. "." .. ext

  -- A non-empty output for this hash means the diagram was rendered before.
  local function fileNonEmpty(path)
    local a = lfs.attributes(path)
    return a and a.size and a.size > 0
  end
  if fileNonEmpty(plantUmlTargetFilename) then
    texio.write_nl("PlantUML cache hit \"" .. plantUmlTargetFilename .. "\"; skipping execution.")
    return hash
  end

  local plantUmlJar
  if not useServer then
    plantUmlJar = os.getenv("PLANTUML_JAR")
    if not plantUmlJar then
      texio.write_nl("Environment variable PLANTUML_JAR not set.")
      return nil
    end
  end

  texio.write("Executing PlantUML... ")
  local cmd
  if useServer then
    -- Fetch the diagram from the PlantUML server: GET <server>/<format>/~h<hex>.
    local url = server .. "/" .. mode .. "/~h" .. plantUmlHexEncode(sourceContent)
    cmd = [[curl -sS -f -o "]] .. plantUmlTargetFilename .. [[" "]] .. url .. [["]]
  else
    -- Quote the jar path so a PLANTUML_JAR with spaces works, e.g. on Windows
    -- "C:\Program Files (x86)\PlantUML\plantuml.jar" (#7).
    cmd = [[java -Djava.awt.headless=true -jar "]] .. plantUmlJar .. [[" -charset UTF-8 -pipe -t]]
    if (mode == "latex") then
      cmd = cmd .. "latex:nopreamble"
    else
      cmd = cmd .. mode
    end
    cmd = cmd .. [[ < "]] .. plantUmlSourceFilename .. [[" > "]] .. plantUmlTargetFilename .. [["]]
    -- PlantUML's TikZ output runs xelatex internally to measure text, and that
    -- xelatex hangs when TEXMF_OUTPUT_DIRECTORY holds a relative path (set by
    -- lualatex's -output-directory). Clear it for the PlantUML child via a command
    -- prefix -- os.setenv is not reliable for io.popen children across builds. (#27)
    if os.getenv("TEXMF_OUTPUT_DIRECTORY") then
      if package.config:sub(1, 1) == "\\" then
        cmd = [[set "TEXMF_OUTPUT_DIRECTORY=" && ]] .. cmd
      else
        cmd = "env -u TEXMF_OUTPUT_DIRECTORY " .. cmd
      end
    end
  end
  texio.write_nl(cmd)
  local handle,error = io.popen(cmd)
  if not handle then
    texio.write_nl("Error during execution of PlantUML.")
    texio.write_nl(error)
    return nil
  end
  io.close(handle)

  if not fileNonEmpty(plantUmlTargetFilename) then
    -- Remove a possibly empty file (e.g. a failed shell redirect) so it is not
    -- cached as a poisoned result, and leave no target so plantuml.sty typesets
    -- a visible placeholder instead of failing on a missing include. (#16)
    os.remove(plantUmlTargetFilename)
    texio.write_nl("PlantUML did not generate anything.")
    return nil
  end
  return hash
end
