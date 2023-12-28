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
  proc exposeProc(name, impl: NimNode; nameFormatter: string): NimNode =
    result = newStmtList()

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
          genast(name = nameFormatter.replace("$1", $name)):
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

  proc exposeVar(name, impl: NimNode; nameFormatter: string): NimNode =
    result = newStmtList()
    result.add:
      genast(typ = name.getType(), impl, name = nameFormatter.replace("$1", $name)):
        static:
          typeDefs.add TypeDef[typeof(typ)].toCType()
          variables.add "static "
          variables.add InsideProc[typeof(typ)].toCType()
          variables.add " "
          variables.add name
          variables.add ";\n"

  macro expose*(nameFormatter: static string; prc: typed): untyped =
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
      result = exposeProc(name, impl, nameFormatter)
    else:
      result = exposeVar(name, impl, nameFormatter)
    result.add prc

else:
  macro expose*(name: static string; t: typed): untyped =
    t

proc toCType*(_: typedesc[TypeDef[cstring]]): string =
  ""

proc toCType*(_: typedesc[InsideProc[cstring]]): string =
  "char*"
