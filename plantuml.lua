-- SPDX-License-Identifier: LPPL-1.3c+

require "lfs"

-- @param mode directly passed to PlantUML. Recommended: png, svg, pdf (requires Apache Batik to convert svg to pdf)
function convertPlantUmlToTikz(jobname, mode)
  local plantUmlSourceFilename = jobname .. "-plantuml.txt"
  local plantUmlTargetFilename = jobname .. "-plantuml." .. mode

  if not (lfs.attributes(plantUmlSourceFilename)) then
    texio.write_nl("Source " .. plantUmlSourceFilename .. " does not exist.")
    return
  end

  local plantUmlJar = os.getenv("PLANTUML_JAR")
  if not plantUmlJar then
    texio.write_nl("Environment variable PLANTUML_JAR not set.")
    return
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
  local cmd = "java -Djava.awt.headless=true -jar " .. plantUmlJar .. " -charset UTF-8 -t"
  if (mode == "latex") then
    cmd = cmd .. "latex:nopreamble"
    -- plantuml has changed output format in https://github.com/plantuml/plantuml/pull/1237
    plantUmlTargetFilename = jobname .. "-plantuml.tex"
  else
    cmd = cmd .. mode
  end


  cmd = cmd .. [[ "]] .. plantUmlSourceFilename .. [["]]
  texio.write_nl(cmd)
  local handle,error = io.popen(cmd)
  if not handle then
    texio.write_nl("Error during execution of PlantUML.")
    texio.write_nl(error)
    return
  end
  io.close(handle)

  if not (lfs.attributes(plantUmlTargetFilename)) then
    texio.write_nl("PlantUML did not generate anything.")
    handle = io.open(plantUmlTargetFilename, "w")
    handle:write("Error during latex code generation")
    io.close(handle)
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
