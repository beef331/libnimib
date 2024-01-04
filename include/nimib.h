#include <stdbool.h>

extern bool nimib_debug;

void nimib_free_string(char *cstr);

// Sets a triplet for what to do when reaching `ext`
char *nimib_set_ext_cmd_language(char *ext, char *cmd, char *language);

// Intitialises Nimib and sets the default language settings
char *nimib_init(char *file, char *defaultExt, char *defaultCmd,
                 char *defaultLanguageName);

// Lowest level block allowing arbitrary blocks to be made
void nimib_add_block(char *command, char *code, char *output);

// Adds source, this will run using the `defaultExt` set by `nimib_init`
char *nimib_add_code(char *source);

// Adds source, this will run using `ext`
// `nimib_set_ext_cmd_language` should have been called prior to setup what,
// to do with the `ext`.
char *nimib_add_code_with_ext(char *source, char *ext);

// Adds text which can contain Markdown
void nimib_add_text(char *output);

// Adds an image that points to `url` with a `caption` and `alt` url
char *nimib_add_image(char *url, char *caption, char *alt);

// Adds file from `path` and annotates it with the `path`
char *nimib_add_file(char *path);

// Adds file from `content` and annotates it with `name`
char *nimib_add_file_name_content(char *name, char *content);

// Saves the generated doc to a `html` relative to the current working directory
char *nimib_save();
