import pkg/nimib
import pkg/nimib/[themes, renders]
import std/[paths, tempfiles, osproc, strutils, tables, appdirs]
import libnimib/utils

const nameStr = "nimib_$1"

{.pragma: nimibProc, raises: [], exportC: nameStr, dynlib.}
{.pragma: nimibVar, exportc: nameStr, dynlib.}

type
  LanguageEntry = object
    ext, cmd, language: string

proc toCType(_: typedesc[TypeDef[bool]]): string =
  ""

proc toCType(_: typedesc[InsideProc[bool]]): string =
  headers.incl "<stdbool.h>"
  "bool"

var
  nb: NbDoc
  defaultFileExt: string
  stringTable: Table[cstring, string]
  extData: Table[string, LanguageEntry]
  debug {.nimibVar, expose: nameStr.}: bool

template print(msg: string) = # Template to elison copies
  if debug:
    echo "[Nimib Debug]:", msg

proc makeErrStr(s: sink string): cstring =
  result = cstring s
  stringTable[cstring s] = ensuremove s

proc free_string(cstr: cstring) {.nimibproc, expose: nameStr.} =
  if cstr in stringTable:
    stringTable.del(cstr)

template returnException(exp: typed): untyped =
  try:
    {.cast(raises: [CatchableError]).}:
      exp
  except CatchableError as e:
    return makeErrStr e.msg

template returnIfNotNil(expr: cstring) =
  let theExpr = expr
  if theExpr != nil:
    return theExpr

proc set_ext_cmd_language(
    ext, cmd: cstring; language = cstring(nil)
): cstring {.nimibProc, expose: nameStr.} =
  returnException:
    let ext = $ext
    extData[ext] = LanguageEntry(ext: ext, cmd: $cmd, language: $language)
    print "Added language entry: " & $extData[ext]

proc setDefault(ext, cmd, language: cstring): cstring =
  if ext == nil:
    return cstring"No default extension provided."
  if cmd == nil:
    return cstring"No default commmand provided."
  defaultFileExt = $ext
  set_ext_cmd_language(ext, cmd, language)

proc init*(
    file, defaultExt, defaultCmd: cstring; defaultLanguageName = cstring(nil)
): cstring {.nimibProc, expose: nameStr.} =
  let
    theme = useDefault
    backend = useHtmlBackend

  returnException:
    nb.initDir = AbsoluteDir getCurrentDir()
    nb.thisFile = AbsoluteFile $file

  returnException:
    nb.source = read(nb.thisFile)

  returnIfNotNil:
    setDefault(defaultExt, defaultCmd, defaultLanguageName)

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
  nb.context = newContext(searchDirs = @[])
    # templateDirs and partials added during nbSave

  returnException:
    # apply render backend (default backend can be overriden by theme)
    backend nb

    # Following is required for adding syntax highlighting in HTML/JS
    nb.partials["nbArbitraryCode"] =
      """
{{>nbArbitraryCodeSource}}
{{>nbCodeOutput}}"""
    nb.partials["nbArbitraryCodeSource"] =
      "<pre><code class=\"hljs {{&language}}\">{{&codeHighlighted}}</code></pre>"
    nb.renderPlans["nbArbitraryCode"] = @["highlightCode"]
    theme nb

proc add_block*(command, code, output: cstring) {.nimibProc, expose: nameStr.} =
  let
    blk =
      NbBlock(
        command: $command,
        code: $code,
        output: $output,
        context: newContext(searchDirs = @[], partials = nbDoc.partials),
      )
  nb.blocks.add blk
  nb.blk = blk

proc getCmd(cmd, ext: cstring): tuple[isErr: bool, data: string] {.raises: [].} =
  if cmd != nil:
    (false, $cmd)
  elif ext != nil:
    let ext = $ext
    if ext in extData:
      {.cast(raises: []).}:
        (false, extData[ext].cmd)
    else:
      (true, "No registered command for extension '" & ext & "'.")
  elif defaultFileExt != "":
    print "Using default file extension"
    getCmd(cmd, cstring defaultFileExt)
  else:
    (true, "No default extension.")

proc addCodeImpl(source, ext, cmd, language: cstring): cstring {.raises: [].} =
  let (cmdErrored, cmd) = getCmd(cmd, ext)

  if cmdErrored:
    return makeErrStr cmd

  let
    ext =
      if ext == nil:
        defaultFileExt
      else:
        $ext

    language =
      if ext in extData:
        {.cast(raises: []).}:
          extData[ext].language
      else:
        $language

  if ext == "":
    return "File extenstion not set"
  if cmd == "":
    return "Exec string not set"
  if source == nil:
    return "No source specified"

  var
    output: string
    path: string

  print "Adding block for: " & $(extension: ext, command: cmd, language: language)

  returnException:
    let (tempFile, temppath) = createTempFile("nimib_", ext, getTempDir().string)
    print "Created path: " & temppath
    tempFile.write($source)
    tempFile.flushFile()
    tempFile.close()
    path = temppath

  returnException:
    output = execProcess(cmd.replace("$file", path))

  print "Block output:\n" & output

  add_block("nbArbitraryCode", source, cstring output)
  if language != "":
    nb.blk.context["language"] = "language-" & language
  else:
    print "Not adding language syntax"
  nb.blk.context["code"] = nb.blk.code
  nb.blk.context["output"] = nb.blk.output

proc add_code*(source: cstring): cstring {.nimibProc, expose: nameStr.} =
  addCodeImpl(source, nil, nil, nil)

proc add_code_with_ext*(source, ext: cstring): cstring {.nimibProc, expose: nameStr.} =
  addCodeImpl(source, ext, nil, nil)

proc add_text*(output: cstring) {.nimibproc, expose: nameStr.} =
  add_block("nbText", "", output)

proc add_image*(url, caption, alt: cstring): cstring {.nimibProc, expose: nameStr.} =
  returnException:
    nbImage($url, $caption, $alt)

proc add_file(path: cstring): cstring {.nimibProc, expose: nameStr.} =
  returnException:
    nbFile($path)

proc add_file_name_content(
    name, content: cstring
): cstring {.nimibProc, expose: nameStr.} =
  returnException:
    nbFile($name, $content)

proc save*(): cstring {.nimibproc, expose: nameStr.} =
  returnException:
    nbSave()

when defined(genHeader):
  static:
    makeHeader("include/nimib.h")
