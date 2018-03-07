-- SPDX-License-Identifier: LPPL-1.3c+

require "lfs"

-- @param mode directly passed to PlantUML. Recommended: png, svg, pdf (requires Apache Batik to convert svg to pdf)
function convertPlantUmlToTikz(jobname, mode)
  local plantUmlSourceFilename = jobname .. "-plantuml.txt"
  local plantUmlTargetFilename = jobname .. "-plantuml." .. mode

  -- delete generated file to ensure they are really recreated
  os.remove(plantUmlTargetFilename)

  if not (lfs.attributes(plantUmlSourceFilename)) then
    texio.write_nl("Source " .. plantUmlSourceFilename .. " does not exist.")
    return
  end

  local plantUmlJar = os.getenv("PLANTUML_JAR")
  if not plantUmlJar then
    texio.write_nl("Environment variable PLANTUML_JAR not set.")
    return
  end

  texio.write("Executing PlantUML... ")
  local cmd = "java -jar " .. plantUmlJar .. " -t"
  if (mode == "latex") then
    cmd = cmd .. "latex:nopreamble"
  else
    cmd = cmd .. mode
  end
  cmd = cmd .. " " .. plantUmlSourceFilename
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
  end
end
