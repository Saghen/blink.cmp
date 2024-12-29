fn main() {
    // delete existing version file created by downloader
    let _ = std::fs::remove_file("target/release/version");

    // get current sha from git
    let output = std::process::Command::new("git")
        .args(["rev-parse", "HEAD"])
        .output()
        .unwrap();
    let sha = String::from_utf8(output.stdout).unwrap();

    // write to version
    std::fs::create_dir_all("target/release").unwrap();
    std::fs::write("target/release/version", sha.trim()).unwrap();
}
