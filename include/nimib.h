#include <stdbool.h>

bool nimib_debug;

void nimib_free_string(char* str);

char* nimib_set_ext_cmd_language(char* ext, char* cmd, char* language);
char *nimib_init(char* filepath, char* ext, char* cmd, char* language);
char *nimib_save(void);

void nimib_add_block(char* command, char* source, char* output);

char *nimib_add_code(char* source);
char *nimib_add_code_with_ext(char* source, char* ext);

void nimib_add_text(char* text);

char *nimib_add_image(char* url, char* caption, char* altText);

char *nimib_add_file(char* path);
char *nimib_add_file_name_content(char* name, char* content);
