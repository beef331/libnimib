#include <stdbool.h>
static bool nimib_debug;
void nimib_free_string(char* cstr);
char* nimib_set_ext_cmd_language(char* ext, char* cmd, char* language);
char* nimib_init(char* file, char* defaultExt, char* defaultCmd, char* defaultLanguageName);
void nimib_add_block(char* command, char* code, char* output);
char* nimib_add_code(char* source);
char* nimib_add_code_with_ext(char* source, char* ext);
void nimib_add_text(char* output);
char* nimib_add_image(char* url, char* caption, char* alt);
char* nimib_add_file(char* path);
char* nimib_add_file_name_content(char* name, char* content);
char* nimib_save();
