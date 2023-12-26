use std::file;
use std::ffi::c_char;
use std::ffi::CString as CString;

type RealCstring = *const c_char;

#[link(name = "nimib")]
extern {
    fn nimib_set_file_ext(ext: RealCstring);
    fn nimib_set_exec_cmd(ext: RealCstring);
    fn nimib_init(file_path: RealCstring) -> RealCstring;
    fn nimib_add_block(name: RealCstring, source: RealCstring, output: RealCstring);
    fn nimib_add_code(code: RealCstring) -> RealCstring;
    fn nimib_add_code_with_ext(code: RealCstring, ext: RealCstring) -> RealCstring;
    fn nimib_add_code_with_ext_cmd(code: RealCstring, ext: RealCstring, cmd: RealCstring) -> RealCstring;
    fn nimib_add_text(text: RealCstring);
    fn nimib_save();

}

use std::stringify;
fn main(){
    unsafe{
        let file_ext = CString::new(".rs").expect("Cannot Allocate");
        let exec_cmd = CString::new("rustc -o $file.out $file >> /dev/null; $file.out").expect("Cannot Allocate");

        nimib_set_file_ext(file_ext.as_ptr());
        nimib_set_exec_cmd(exec_cmd.as_ptr());

        let file_name = CString::new(file!()).expect("Cannot Allocate");
        nimib_init(file_name.as_ptr());
        let title_text = CString::new(r#"# This is Nimib from Rust!

This is sorta cool, though it's Rust so .... bleh"#).expect("Cannot Allocate");
        nimib_add_text(title_text.as_ptr());

        let program = CString::new(stringify!( // This really does not multiline?!
            fn main(){
                println!("Hello, world!");
                println!("Hmm!");
            })).expect("Cannot Allocate");
 
        nimib_add_code(program.as_ptr());
        let subtext = CString::new("It's pretty easy still").expect("Cannot Allocate");
        nimib_add_text(subtext.as_ptr());
        nimib_save();
    }
}
