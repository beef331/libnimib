import pkg/[nimib, seeya]
import pkg/nimib/[themes, renders]
import std/[paths, tempfiles, osproc, strutils, tables, appdirs]


const nameStr = "nimib_$1"
static: setFormatter nameStr
{.pragma: nimibProc, raises: [], exportC: nameStr, dynlib.}
{.pragma: nimibVar, exportc: nameStr, dynlib.}

type
  LanguageEntry = object
    ext, cmd, language: string

var
  nb: NbDoc
  defaultFileExt: string
  stringTable: Table[cstring, string]
  extData: Table[string, LanguageEntry]
  debug {.nimibVar, expose.}: bool

template print(msg: string) = # Template to elison copies
  if debug:
    echo "[Nimib Debug]:", msg

proc makeErrStr(s: sink string): cstring =
  result = cstring s
  stringTable[cstring s] = ensuremove s

proc free_string(cstr: cstring) {.nimibproc, expose.} =
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
): cstring {.nimibProc, expose.} =
  ## Sets a triplet for what to do when reaching `ext`
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
): cstring {.nimibProc, expose.} =
  ## Intitialises Nimib and sets the default language settings

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

proc add_block*(command, code, output: cstring) {.nimibProc, expose.} =
  ## Lowest level block allowing arbitrary blocks to be made
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

proc add_code*(source: cstring): cstring {.nimibProc, expose.} =
  ## Adds source, this will run using the `defaultExt` set by `nimib_init`
  addCodeImpl(source, nil, nil, nil)

proc add_code_with_ext*(source, ext: cstring): cstring {.nimibProc, expose.} =
  ## Adds source, this will run using `ext`
  ## `nimib_set_ext_cmd_language` should have been called prior to setup what,
  ## to do with the `ext`.
  addCodeImpl(source, ext, nil, nil)

proc add_text*(output: cstring) {.nimibproc, expose.} =
  ## Adds text which can contain Markdown
  add_block("nbText", "", output)

proc add_image*(url, caption, alt: cstring): cstring {.nimibProc, expose.} =
  ## Adds an image that points to `url` with a `caption` and `alt` url
  returnException:
    nbImage($url, $caption, $alt)

proc add_file(path: cstring): cstring {.nimibProc, expose.} =
  ## Adds file from `path` and annotates it with the `path`
  returnException:
    nbFile($path)

proc add_file_name_content(name, content: cstring): cstring {.nimibProc, expose.} =
  ## Adds file from `content` and annotates it with `name`
  returnException:
    nbFile($name, $content)

proc save*(): cstring {.nimibproc, expose.} =
  ## Saves the generated doc to a `html` relative to the current working directory
  returnException:
    nbSave()

makeHeader("include/nimib.h")
when defined(genHeader):
  static: discard staticExec("clang-format -i ../include/nimib.h")
