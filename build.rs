fn main() {
    // delete existing version.txt file created by downloader
    let _ = std::fs::remove_file("target/release/version.txt");
}
