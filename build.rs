use std::env;
use std::fs::File;
use std::io::Write;
use std::path::Path;

fn main() {
    let rust_output = Path::new(&env::var("OUT_DIR").unwrap()).join("ffi.rs");

    let output = generator::generate(
        &env::current_dir()
            .unwrap()
            .as_path()
            .join("lua/blink/cmp/fuzzy/ffi.rs"),
        "blink-cmp-fuzzy",
        false,
    );

    File::create(rust_output.clone())
        .unwrap()
        .write_all(output.as_bytes())
        .unwrap();

    assert!(rust_output.exists());
}
