--experimental: strictdefs
--app:lib
--d:nimibSkipOptions

task installLib, "installs libnimib":
  selfExec("c -d:release src/nimib.nim")
  exec("sudo mv src/libnimib.so /usr/lib64/")

task testc, "builds the C program":
  exec("gcc -Iinclude -lnimib -o test.out tests/test.c")
  exec("./test.out")
