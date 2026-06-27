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
function convertPlantUmlToTikz(jobname, mode, iodir, server)
  iodir = iodir or ""
  server = server or ""
  if server == "" then server = os.getenv("PLANTUML_SERVER") or "" end
  while server:sub(-1) == "/" do server = server:sub(1, -2) end
  local useServer = (server ~= "") and (mode == "png" or mode == "svg")

  local plantUmlSourceFilename = iodir .. jobname .. "-plantuml.txt"
  local plantUmlTargetFilename = iodir .. jobname .. "-plantuml." .. mode

  if not (lfs.attributes(plantUmlSourceFilename)) then
    texio.write_nl("Source " .. plantUmlSourceFilename .. " does not exist.")
    return
  end

  local plantUmlJar
  if not useServer then
    plantUmlJar = os.getenv("PLANTUML_JAR")
    if not plantUmlJar then
      texio.write_nl("Environment variable PLANTUML_JAR not set.")
      return
    end
  end

  -- check if plantUmlSourceFilename is the same as sourceCacheFilename, if yes, skip executing PlantUML
  local sourceCacheFilename = plantUmlSourceFilename .. "." .. mode .. ".cache"
  local sourceCacheHandle = io.open(sourceCacheFilename, "r")
  if sourceCacheHandle then
    texio.write_nl("Cache \"" .. sourceCacheFilename .. "\" exists.")
    local sourceCacheContent = sourceCacheHandle:read("*a")
    io.close(sourceCacheHandle)

    local sourceHandle = io.open(plantUmlSourceFilename, "r")
    if not sourceHandle then
      texio.write_nl("Error: Could not open source file for reading.")
    end
    local sourceContent = sourceHandle:read("*a")
    io.close(sourceHandle)

    if sourceContent == sourceCacheContent then
      texio.write_nl("Source \"" .. plantUmlSourceFilename .. "\" is unchanged, skipping PlantUML execution.")
      return
    else
      texio.write_nl("Source \"" .. plantUmlSourceFilename .. "\" has changed. ")
    end
  end
  -- delete generated file to ensure they are really recreated
  os.remove(plantUmlTargetFilename)

  texio.write("Executing PlantUML... ")
  local cmd
  if useServer then
    -- Fetch the diagram from the PlantUML server: GET <server>/<format>/~h<hex>.
    local sourceHandle = io.open(plantUmlSourceFilename, "rb")
    if not sourceHandle then
      texio.write_nl("Error: Could not open source file for reading.")
      return
    end
    local sourceContent = sourceHandle:read("*a")
    io.close(sourceHandle)
    local url = server .. "/" .. mode .. "/~h" .. plantUmlHexEncode(sourceContent)
    cmd = [[curl -sS -f -o "]] .. plantUmlTargetFilename .. [[" "]] .. url .. [["]]
  else
    cmd = "java -Djava.awt.headless=true -jar " .. plantUmlJar .. " -charset UTF-8 -pipe -t"
    if (mode == "latex") then
      cmd = cmd .. "latex:nopreamble"
      -- plantuml has changed output format in https://github.com/plantuml/plantuml/pull/1237
      plantUmlTargetFilename = iodir .. jobname .. "-plantuml.tex"
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
    return
  end
  io.close(handle)

  if not (lfs.attributes(plantUmlTargetFilename)) then
    -- Leave no target file: plantuml.sty then typesets a visible placeholder
    -- instead of failing on a missing \input/\includegraphics. (#16)
    texio.write_nl("PlantUML did not generate anything.")
    return
  else
    -- cache plantUmlSourceFilename for next run
    texio.write_nl("Caching source file \"" .. plantUmlSourceFilename .. "\" to \"" .. sourceCacheFilename .. "\".")
    local sourceHandle = io.open(plantUmlSourceFilename, "r")
    if sourceHandle then
      local cacheHandle = io.open(sourceCacheFilename, "w")
      if cacheHandle then
      cacheHandle:write(sourceHandle:read("*a"))
      io.close(cacheHandle)
      else
      texio.write_nl("Error: Could not open cache file for writing.")
      end
      io.close(sourceHandle)
    else
      texio.write_nl("Error: Could not open source file for reading.")
    end
  end
end
