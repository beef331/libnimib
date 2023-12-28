#include "nimib.h"
int main() {
  nimib_debug = 1;
  nimib_init(__FILE__,
             ".c",
             "gcc -o $file.out $file > /dev/null; $file.out",
             "C");

  nimib_set_ext_cmd_language(".py", "python $file", "python");
  nimib_set_ext_cmd_language(".rs", "rustc -o $file.out $file >> /dev/null; $file.out", "rust");
  nimib_set_ext_cmd_language(".rkt", "racket $file", "lisp");

  nimib_add_image("https://nim-lang.org/assets/img/logo.svg", 0,
                  "Nim-lang logo here");
  nimib_add_text("# This is Nimib from C!\n"
                 "It is a wonderful thing to be able to use nimib from C.\n"
                 "It allows you to do wonderful things!\n"
                 "The following is the simple ABI that it exposes in C syntax");

  nimib_add_file("include/nimib.h");

  nimib_add_code_with_ext("//C\n#include <stdio.h>\n"
                           "#include <stdlib.h>\n"
                           "int main(){\n"
                           "  int *i = (int*)malloc(sizeof(int));\n"
                           "  printf(\"%ld\", i);\n"
                           "  return 0;\n"
                           "}\n",
                           ".c");

  nimib_add_code(R"""(
//C
#include <stdio.h>
#include <stdlib.h>
int main(){
  printf("Hello, world!\n");
  int *i = (int*)malloc(sizeof(int));
  printf("%ld", i);
  return 0;
}
)""");

  nimib_add_code_with_ext("'''Python'''\nprint('hello world')", ".py");

  nimib_add_code_with_ext(
      R"""(
//Rust
fn main(){
  println!("Hello, world");
  println!("Huh")

}

  )""",
      ".rs");

  nimib_add_code_with_ext(";Racket\n#lang racket/base\n(displayln \"Hello, "
                                   "World\")\n(displayln (+ 10 20))\n",
                                   ".rkt");

  nimib_add_text("As you can see it's very easy to do!");
  nimib_save();
  return 0;
}
