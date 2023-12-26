void nimib_set_exec_cmd(char *);
void nimib_set_file_ext(char *);

void nimib_set_ext_cmd(char *, char *);

void nimib_free_string(char *);

char *nimib_init(char *);
char *nimib_save(void);

void nimib_add_block(char *, char *, char *);

char *nimib_add_code(char *);
char *nimib_add_code_with_lang(char *, char *);

char *nimib_add_code_with_ext(char *, char *);
char *nimib_add_code_with_ext_lang(char *, char *, char *);

char *nimib_add_code_with_ext_cmd(char *, char *, char *);
char *nimib_add_code_with_ext_cmd_lang(char *, char *, char *, char *);

void nimib_add_text(char *);
