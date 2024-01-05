use std::ffi::c_char;
use std::ffi::CString;
use std::file;

type RealCstring = *const c_char;

#[link(name = "nimib")]
extern "C" {
    fn nimib_set_file_ext_cmd_language(ext: RealCstring, cmd: RealCstring, language: RealCstring);
    fn nimib_init(file_path: RealCstring, ext: RealCstring, cmd: RealCstring, language: RealCstring) -> RealCstring;
    fn nimib_add_block(name: RealCstring, source: RealCstring, output: RealCstring);
    fn nimib_add_code(code: RealCstring) -> RealCstring;
    fn nimib_add_code_with_ext(code: RealCstring, ext: RealCstring) -> RealCstring;
    fn nimib_add_text(text: RealCstring);
    fn nimib_add_image(url: RealCstring, caption: RealCstring, alt: RealCstring) -> RealCstring;
    fn nimib_add_file(path: RealCstring) -> RealCstring;
    fn nimib_add_file_name_content(name: RealCstring, content: RealCstring);
    fn nimib_save() -> RealCstring;

}

fn make_cstring(str: &str) -> CString {
    CString::new(str).expect("Cannot Allocate")
}

use std::stringify;
fn main() {
    unsafe {
        nimib_init(
            make_cstring(file!()).as_ptr(),
            make_cstring(".rs").as_ptr(),
            make_cstring("rustc -o $file.out $file >> /dev/null; $file.out").as_ptr(),
            make_cstring("rust").as_ptr()
        );
        let title_text = make_cstring(
            r#"# This is Nimib from Rust!

This is sorta cool, though it's Rust so .... bleh"#,
        );
        nimib_add_text(title_text.as_ptr());

        let program = make_cstring(stringify!(
            fn main() {
                println!("Hello, world!");
                println!("Hmm!");
            }
        ));

        nimib_add_code(program.as_ptr());
        nimib_add_text(make_cstring("It's pretty easy still").as_ptr());
        nimib_save();
    }
}
