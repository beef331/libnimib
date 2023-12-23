import pkg/nimib
import pkg/nimib/[config, themes, renders]
import std/[dirs, paths, tempfiles, osproc, strutils, tables, appdirs]


{.pragma: nimibProc, exportc: "nimib_$1", cdecl, dynlib, raises: [].}
{.pragma: nimibVar, exportc: "nimib_$1", dynlib.}

var 
  nb: NbDoc
  exec_cmd {.nimibVar.}: cstring
  file_ext {.nimibVar.}: cstring
  stringTable: Table[cstring, string]

proc free_string(cstr: cstring) {.nimibproc.} =
  if cstr in stringTable:
    stringTable.del(cstr)


template returnException(exp: typed): untyped =
  try:
    {.cast(raises:[CatchableError]).}:
      exp
  except CatchableError as e:
    var msg = e.msg
    let theCstr = cstring msg
    stringTable[theCstr] = move msg
    return theCstr


proc init*(file: cstring): cstring {.nimibProc.} =
  let
    theme = useDefault
    backend = useHtmlBackend
  
  returnException:
    nb.initDir = AbsoluteDir getCurrentDir()
    nb.thisFile = AbsoluteFile $file

  returnException:
    nb.source = read(nb.thisFile)

    # no option handling currently
  nb.filename = nb.thisFile.Path.splitFile.name.string & ".html"
  
  if nb.cfg.srcDir != "":
    returnException:
      nb.filename = string (nb.thisDir.relativeTo nb.srcDir).Path / nb.filename.Path

  if nb.cfg.homeDir != "":
    returnException:
      setCurrentDir nb.homeDir

  # can be overriden by theme, but it is better to initialize this anyway
  nb.templateDirs = @["./", "./templates/"]
  nb.partials = initTable[string, string]()
  nb.context = newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  returnException:
    # apply render backend (default backend can be overriden by theme)
    backend nb
    # apply theme
    theme nb

proc add_block*(command, code, output: cstring) {.nimibProc.} =
  let blk = NbBlock(command: $command, code: $code, output: $output, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  nb.blocks.add blk
  nb.blk = blk

proc add_code*(source: cstring): cstring {.nimibProc.} =
  var 
    output: string
    path: string
  returnException:
    let (tempFile, temppath) = createTempFile("nimib_", $file_ext, getTempDir().string)
    tempFile.write($source)
    tempFile.flushFile()
    tempFile.close()
    path = temppath

  returnException:
    output = execProcess(($exec_cmd).replace("$file", path))
  
  add_block("nbCode", $source, output)
  nb.blk.context["code"] = nb.blk.code
  nb.blk.context["output"] = nb.blk.output

proc add_text*(output: cstring) {.nimibproc.} =
  add_block("nbText", "", output)

proc save*(): cstring {.nimibproc.} =
  returnException:
    nbSave()
