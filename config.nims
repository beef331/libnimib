--app:
  lib
--d:
  nimibSkipOptions

task installLib, "installs libnimib":
  selfExec("c -d:release src/nimib.nim")
  exec("sudo mv src/libnimib.so /usr/lib64/")

task testc, "builds the C program":
  exec("gcc -Iinclude -lnimib -o test.c.out tests/test.c")
  exec("./test.c.out")

task testrust, "builds the Rust program":
  exec("rustc  -o test.rust.out tests/test.rs")
  exec("./test.rust.out")

task testracket, "builds the Racket program":
  exec("racket ./tests/test.rkt")

task genHeader, "Generates the header file":
  selfExec("c -c -d:genHeader -f src/nimib.nim")
