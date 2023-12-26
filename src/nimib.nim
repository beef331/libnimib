import pkg/nimib
import pkg/nimib/[config, themes, renders]
import std/[dirs, paths, tempfiles, osproc, strutils, tables, appdirs]


{.pragma: nimibProc, exportc: "nimib_$1", cdecl, dynlib, raises: [].}
{.pragma: nimibVar, exportc: "nimib_$1", dynlib.}

var 
  nb: NbDoc
  execCmd: string
  fileExt: string
  stringTable: Table[cstring, string]
  extCommand: Table[string, string]
  
proc makeErrStr(s: sink string): cstring =
  result = cstring s
  stringTable[cstring s] = ensuremove s

proc free_string(cstr: cstring) {.nimibproc.} =
  if cstr in stringTable:
    stringTable.del(cstr)

# The follow procs are not apart of `init` to allow the user to have multiple programming languages
# This allows doing C then Python then Rust, or whatever have you
# Perhaps in the future `add_code` could take in `language`,
# then use that to search a config for the desired command

proc set_exec_cmd(cmd: cstring) {.nimibproc.} =
  execCmd = $cmd

proc set_file_ext(ext: cstring) {.nimibproc.} =
  fileExt = $ext

proc set_ext_cmd(ext, cmd: cstring) {.nimibproc.} =
  extCommand[$ext] = $cmd

template returnException(exp: typed): untyped =
  try:
    {.cast(raises:[CatchableError]).}:
      exp
  except CatchableError as e:
    return makeErrStr e.msg
   
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

proc getCmd(cmd, ext: cstring): tuple[isErr: bool, data: string] {.raises: [].}=
  if cmd != nil:
    (false, $cmd)
  elif ext == nil:
    (false, execCmd)
  else:
    let ext = $ext
    if ext notin extCommand:
      (true, "No command registered for '" & ext & "'.")
    else:
      {.cast(raises: []).}:
        (false, extCommand[$ext])

proc addCodeImpl(source, ext, cmd: cstring): cstring {.raises: [].} =
  let 
    (cmdErrored, cmd) = getCmd(cmd, ext)
    ext = 
      if ext == nil:
        fileExt
      else:
        $ext

  if cmdErrored:
    return makeErrStr cmd

  var 
    output: string
    path: string

  if ext == "":
    return "File extenstion not set"
  if cmd == "":
    return "Exec string not set"
  if source == nil:
    return "No source specified"

  returnException:
    let (tempFile, temppath) = createTempFile("nimib_", ext, getTempDir().string)
    tempFile.write($source)
    tempFile.flushFile()
    tempFile.close()
    path = temppath

  returnException:
    output = execProcess(cmd.replace("$file", path))
  
  add_block("nbCode", $source, output)
  nb.blk.context["code"] = nb.blk.code
  nb.blk.context["output"] = nb.blk.output


proc add_code*(source: cstring): cstring {.nimibProc.} =
  addCodeImpl(source, nil, nil)

proc add_code_with_ext*(source, ext: cstring): cstring {.nimibProc.} =
  addCodeImpl(source, ext, nil)

proc add_code_with_ext_cmd*(source, ext, cmd: cstring): cstring {.nimibProc.} =
  addCodeImpl(source, ext, cmd)

proc add_text*(output: cstring) {.nimibproc.} =
  add_block("nbText", "", output)

proc save*(): cstring {.nimibproc.} =
  returnException:
    nbSave()
