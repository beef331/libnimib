import std/[macros, sets, strutils, hashes, genasts, strformat, os]
export sets
type
  InsideProc*[T] = distinct void
  TypeDef*[T] = distinct void

proc hash(node: NimNode): Hash =
  hash(cast[int](node))

var
  headers* {.compileTime.}: HashSet[string]
  typeDefs {.compileTime.} = ""
  procDefs {.compileTime.} = ""
  variables {.compileTime.} = ""
  generatedTypes {.compileTime.}: HashSet[NimNode]

macro makeHeader*(location: static string): untyped =
  var file = ""
  for header in headers:
    file.add fmt "#include {header}\n"

  file.add typeDefs
  file.add variables
  file.add procDefs

  writeFile(location, file)

proc genTypeDefCall(typ: NimNode): NimNode =
  if typ notin generatedTypes:
    generatedTypes.incl typ
    genAst(typ):
      static:
        typeDefs.add TypeDef[typ].toCType()
  else:
    nil

proc genProcCall(typ, name: Nimnode; isLast: bool): NimNode =
  let
    name =
      if name.kind == nnkEmpty:
        ""
      else:
        $name
  genAst(typ, isLast, name):
    static:
      procDefs.add InsideProc[typ].toCType()
      if name != "":
        procDefs.add " "
        procDefs.add name
      if not isLast:
        procDefs.add ", "

when defined(genHeader):
  var exposeFormatter {.compileTime.} = "$1"

  proc setFormatter*(formatter: static string) {.compileTime.} =
    when "$1" notin formatter:
      {.error: "Formatter does not contain '$1' so cannot be used.".}
    exposeFormatter = formatter

  proc getComments(node: NimNode; result: var string) =
    for child in node:
      if child.kind == nnkCommentStmt:
        if result.len == 0:
          result.add "\n"
        result.add "// "
        result.add child.strVal.replace("\n", "\n// ")
        result.add "\n"
      else:
        getComments(child, result)

  proc getComments(name: NimNode): string =
    let impl = name.getImpl[^2]
    getComments(impl, result)

  proc exposeProc(name, impl: NimNode): NimNode =
    let comments = name.getComments()
    result = newStmtList()
    result.add:
      genast(comments):
        static:
          procDefs.add comments
    for i, x in impl[0]:
      if i == 0:
        if x.kind != nnkEmpty:
          result.add genTypeDefCall(x)
          result.add genProcCall(x, newEmptyNode(), true)
        else:
          result.add:
            genast:
              static:
                procDefs.add "void"
        result.add:
          genast(name = exposeFormatter.replace("$1", $name)):
            static:
              procDefs.add " "
              procDefs.add name
              procDefs.add "("
      else:
        result.add genTypeDefCall(x[^2])
        result.add genProcCall(x[^2], x[0], i == impl[0].len - 1)

    result.add:
      genast:
        static:
          procDefs.add ");\n"

  proc exposeVar(name, impl: NimNode): NimNode =
    result = newStmtList()
    result.add:
      genast(typ = name.getType(), impl, name = exposeFormatter.replace("$1", $name)):
        static:
          typeDefs.add TypeDef[typeof(typ)].toCType()
          variables.add "static "
          variables.add InsideProc[typeof(typ)].toCType()
          variables.add " "
          variables.add name
          variables.add ";\n"

  macro expose*(prc: typed): untyped =
    let
      name =
        case prc.kind
        of nnkProcDef:
          prc[0]
        of nnkSym:
          if prc.symKind notin {nskProc, nskVar}:
            prc
          else:
            error("Expected proc or var symbol", prc)
            return
        of nnkVarSection:
          prc[0][0][0]
        else:
          error("Expected proc definition or variable", prc)
          return

      impl = name.getTypeInst()

    if prc.kind == nnkProcDef:
      result = exposeProc(name, impl)
    else:
      result = exposeVar(name, impl)
    result.add prc

else:
  var exposeFormatter {.compileTime.} = ""
  proc setFormatter*(formatter: static string) {.compileTime.} =
    discard

  macro expose*(t: typed): untyped =
    t

proc toCType*[T: object](t: typedesc[TypeDef[T]]): string {.compileTime.} =
  mixin toCType
  for field in T().fields:
    generatedTypes.incl typeof(field).getType()
    typedefs.add TypeDef[typeof(field)].toCType()

  generatedTypes.incl T.getType()

  result.add "struct "
  result.add exposeFormatter.replace("$1", $T)
  result.add " {\n"
  for field in T().fields:
    result.add "    "
    result.add InsideProc[typeof(field)].toCType()
    result.add " "
    result.add astToStr(field).split(".")[^1] # Ugly
    result.add ";\n"
  result.add "};\n\n"

proc toCType*[T: object](t: typedesc[InsideProc[T]]): string {.compileTime.} =
  "struct " & exposeFormatter.replace("$1", $T)

proc toCType*[T: not object](_: typedesc[TypeDef[T]]): string =
  ""

proc toCType*(_: typedesc[InsideProc[cstring]]): string =
  "char*"

proc toCType*[T: SomeSignedInt](_: typedesc[InsideProc[T]]): string =
  static:
    headers.incl "<stdint.h>"
  when T is int8:
    "int8_t"
  elif T is int16:
    "int16_t"
  elif T is int32:
    "int32_t"
  elif T is int64:
    "int64_t"
  elif T is int:
    "intptr_t"

proc toCType*[T: SomeUnsignedInt](_: typedesc[InsideProc[T]]): string =
  static:
    headers.incl "<stdint.h>"
  when T is uint8:
    "uint8_t"
  elif T is uint16:
    "uint16_t"
  elif T is uint32:
    "uint32_t"
  elif T is uint64:
    "uint64_t"
  elif T is uint:
    "uintptr_t"

proc toCType*[T: float or float64](_: typedesc[InsideProc[T]]): string =
  "double"

proc toCType*(_: typedesc[InsideProc[float32]]): string =
  "float"
