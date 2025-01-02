use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref BACKWARD_REGEX: Regex = Regex::new(r"[\p{L}0-9_][\p{L}0-9_\\-]*$").unwrap();
    static ref FORWARD_REGEX: Regex = Regex::new(r"^[\p{L}0-9_\\-]+").unwrap();
}

/// Given a string, returns the start and end indices of the keyword
pub fn get_keyword_range(line: &str, col: usize, match_suffix: bool) -> (usize, usize) {
    let line_before = line.chars().take(col).collect::<String>();
    let before_match_start = BACKWARD_REGEX.find(&line_before).map(|m| m.start());
    if !match_suffix {
        return (before_match_start.unwrap_or(col), col);
    }

    let line_after = line.chars().skip(col).collect::<String>();
    let after_match_end = FORWARD_REGEX.find(&line_after).map(|m| m.end());
    (
        before_match_start.unwrap_or(col),
        after_match_end.unwrap_or(col),
    )
}

pub fn guess_keyword_range_from_item(
    item_text: &str,
    line: &str,
    cursor_col: usize,
    match_suffix: bool,
) -> (usize, usize) {
    let line_range = get_keyword_range(line, cursor_col, match_suffix);
    let text_range = get_keyword_range(item_text, item_text.len(), false);

    let line_prefix = line.chars().take(line_range.0).collect::<String>();
    let text_prefix = item_text.chars().take(text_range.0).collect::<String>();
    if line_prefix.ends_with(&text_prefix) {
        return (line_range.0 - text_prefix.len(), line_range.1);
    }

    line_range
}

pub fn guess_keyword_from_item(
    item_text: &str,
    line: &str,
    cursor_col: usize,
    match_suffix: bool,
) -> String {
    let (start, end) = guess_keyword_range_from_item(item_text, line, cursor_col, match_suffix);
    line[start..end].to_string()
}
