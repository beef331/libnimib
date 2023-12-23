import pkg/nimib
import pkg/nimib/[config, themes, renders]
import std/[ospaths, dirs, paths, tempfiles, osproc, strutils]


{.pragma: nimibProc, exportc: "nimib_$1", cdecl, dynlib, raises: [].}
{.pragma: nimibVar, exportc: "nimib_$1", dynlib.}

var 
  nb: NbDoc
  exec_cmd {.nimibVar.}: cstring
  file_ext {.nimibVar.}: cstring


const 
  failToReadError = "Fail to read"
  failToCreateFileError = "Fail to create file"
  failToExecError = "Fail to create file"
  failToGetDirError = "Fail to get dir"
  failToRelDir = "Fail to get relative dir"
  failToSetDir = "Fail to set dir"




proc init*(file: cstring): cstring {.nimibProc.} =
  let
    theme = useDefault
    backend = useHtmlBackend
  try:
    nb.initDir = AbsoluteDir getCurrentDir()
    echo string getCurrentDir()
    nb.thisFile = AbsoluteFile $file
  except:
    return failToGetDirError
  try:
    nb.source = read(nb.thisFile)
  except:
    return failToReadError


    # no option handling currently
  nb.filename = nb.thisFile.string.splitFile.name & ".html"
  
  if nb.cfg.srcDir != "":
    try:
      nb.filename = (nb.thisDir.relativeTo nb.srcDir).string / nb.filename
    except:
      return failToRelDir

  if nb.cfg.homeDir != "":
    try:
      setCurrentDir nb.homeDir
    except:
      return failToSetDir

  # can be overriden by theme, but it is better to initialize this anyway
  nb.templateDirs = @["./", "./templates/"]
  nb.partials = initTable[string, string]()
  nb.context = newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  try:
    # apply render backend (default backend can be overriden by theme)
    backend nb

    # apply theme
    theme nb
  except Exception as e:
    echo e.msg 

proc add_block*(command, code, output: cstring) {.nimibProc.} =
  let blk = NbBlock(command: $command, code: $code, output: $output, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  nb.blocks.add blk
  nb.blk = blk

proc add_code*(source: cstring): cstring {.nimibProc.} =
  let output: string
  try:
    let (tempFile, path) = createTempFile("nimib_", $file_ext, getTempDir())
    tempFile.write($source)
    tempFile.flushFile()
    tempFile.close()
    try:
      output = execProcess(($exec_cmd).replace("$file", path))
    except:
      output = ""
      return failToExecError
  except:
    output = ""
    return failToCreateFileError
  
  add_block("nbCode", $source, output)
  nb.blk.context["code"] = nb.blk.code
  nb.blk.context["output"] = nb.blk.output

proc add_text*(output: cstring) {.nimibproc.} =
  add_block("nbText", "", output)

proc save*() {.nimibproc.} =
  try:
    nbSave()
  except Exception as e:
    echo "Failed to save: ", e.msg
