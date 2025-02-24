use std::sync::LazyLock;

use regex::Regex;

static BACKWARD_REGEX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"[\p{L}0-9_][\p{L}0-9_-]*$").unwrap());
static FORWARD_REGEX: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^[\p{L}0-9_-]+").unwrap());

/// Given a line and cursor position, returns the start and end indices of the keyword
pub fn get_keyword_range(line: &str, col: usize, match_suffix: bool) -> (usize, usize) {
    let col = line
        .char_indices()
        .find(|(idx, _)| *idx >= col)
        .map(|(idx, _)| idx)
        .unwrap_or(line.len());

    let before_match_start = BACKWARD_REGEX
        .find(&line[0..col.min(line.len())])
        .map(|m| m.start());
    if !match_suffix {
        return (before_match_start.unwrap_or(col), col);
    }

    let after_match_end = FORWARD_REGEX
        .find(&line[col.min(line.len())..])
        .map(|m| m.end() + col);
    (
        before_match_start.unwrap_or(col),
        after_match_end.unwrap_or(col),
    )
}

/// Given a string, guesses the start and end indices in the line for the specific item
/// 1. Get the keyword range (alphanumeric, underscore, hyphen) on the line and end of the item
///    text
/// 2. Check if the suffix of the item text matches the suffix of the line text, if so, include the
///    suffix in the range
///
/// Example:
///   line: example/str/trim
///   item: str/trim
///   matches on: str/trim
///
///   line: example/trim
///   item: str/trim
///   matches on: trim
///
/// TODO:
///   line: '
///   item: 'tabline'
///   matches on: '
pub fn guess_keyword_range_from_item(
    item_text: &str,
    line: &str,
    cursor_col: usize,
    match_suffix: bool,
) -> (usize, usize) {
    let line_range = get_keyword_range(line, cursor_col, match_suffix);
    let text_range = get_keyword_range(item_text, item_text.len(), false);

    let line_prefix = &line[..line_range.0];
    let text_prefix = &item_text[..text_range.0];
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_keyword_range_unicode() {
        let line = "'вest'";
        let col = line.len() - 1;
        assert_eq!(get_keyword_range(line, col, false), (1, line.len() - 1));
    }
}
