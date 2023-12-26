#include "nimib.h"
int main() {
  nimib_set_file_ext(".c");
  nimib_set_exec_cmd("gcc -o $file.out $file > /dev/null; $file.out");
  nimib_set_ext_cmd(".py", "python $file");
  nimib_init(__FILE__);
  nimib_add_text("# This is Nimib from C!\n"
                 "It is a wonderful thing to be able to use nimib from C.\n"
                 "It allows you to do wonderful things!\n");
  nimib_add_code("#include <stdio.h>\n"
                 "#include <stdlib.h>\n"
                 "int main(){\n"
                 "  int *i = (int*)malloc(sizeof(int));\n"
                 "  printf(\"%ld\", i);\n"
                 "  return 0;\n"
                 "}\n");

  nimib_add_code(R"""(
#include <stdio.h>
#include <stdlib.h>
int main(){
  printf("Hello, world!\n");
  int *i = (int*)malloc(sizeof(int));
  printf("%ld", i);
  return 0;
}
)""");

  nimib_add_code_with_ext("print('hello world')", ".py");

  nimib_add_code_with_ext_cmd(
      R"""(
fn main(){
  println!("Hello, world");
  println!("Huh")

}

  )""",
      ".rs", "rustc -o $file.out $file >> /dev/null; $file.out");

  nimib_add_text("As you can see it's very easy to do!");
  nimib_save();
  return 0;
}
