use std::sync::LazyLock;

use regex::Regex;

static NON_KEYWORD_REGEX: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"[^\p{L}0-9_-]").unwrap());
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
/// 1. Get the typical keyword range (alphanumeric, underscore, hyphen) on the line
/// 2. Scan backwards from the beginning of the typical keyword range
/// 3. For each position, check if the text between the new position and the beginning of the
///    keyword range matches the end of the item text
///
/// For example, for a line like "str/tr" with completion item "str/trim", the matched keyword
/// range would be "tr" initially. We would then check if "/" matches the beginning of the
/// completion item "str/trim". Then we would check "r/", "tr/", and finally "str/". The last one
/// matches the beginning of the completion item, so we would return the range (0, 6).
///
/// Example:
///   line: example/str/tr
///   item: str/trim
///   matches on: str/tr
///
///   line: example/tr
///   item: str/trim
///   matches on: tr
pub fn guess_keyword_range(
    (og_keyword_start, keyword_end): (usize, usize),
    word: &str,
    line: &str,
) -> (usize, usize) {
    // No special logic needed if the whole word matches the keyword regex or if we can't go
    // backwards
    if og_keyword_start == 0 || !NON_KEYWORD_REGEX.is_match(word) {
        return (og_keyword_start, keyword_end);
    }

    let word = word.as_bytes();
    let line = line.as_bytes();

    // Use the keyword regex as the "typical" keyword range
    let mut keyword_start = og_keyword_start;

    // Calculate the range to search backwards (don't go below 0)
    let search_start = og_keyword_start.saturating_sub(word.len());

    // Search backwards from just before the keyword start
    for idx in (search_start..og_keyword_start).rev() {
        // Check if this position could be a valid word boundary
        if !is_valid_word_boundary(line, idx) {
            continue;
        }

        // Abort if we hit whitespace (word boundary)
        if line[idx].is_ascii_whitespace() {
            break;
        }

        // Try to match the completion word starting from this position
        let match_len = og_keyword_start - idx;

        // Don't try to match more characters than we have in either string
        if match_len <= word.len() && idx + match_len <= line.len() {
            let line_substr = &line[idx..idx + match_len];
            let word_substr = &word[0..match_len];

            if line_substr == word_substr {
                keyword_start = keyword_start.min(idx);
            }
        }
    }

    (keyword_start, keyword_end)
}

pub fn guess_keyword(keyword_range: (usize, usize), word: &str, line: &str) -> String {
    let (start, end) = guess_keyword_range(keyword_range, word, line);
    line[start..end].to_string()
}

/// Logic taken directly from nvim-cmp
/// https://github.com/hrsh7th/nvim-cmp/blob/b5311ab3ed9c846b585c0c15b7559be131ec4be9/lua/cmp/utils/char.lua#L70
fn is_valid_word_boundary(text: &[u8], index: usize) -> bool {
    if index == 0 {
        return true;
    }

    if index >= text.len() {
        return false;
    }

    // Check various semantic boundary conditions
    let prev = text[index - 1];
    let curr = text[index];
    return (!prev.is_ascii_uppercase() && curr.is_ascii_uppercase())
        || !curr.is_ascii_alphanumeric()
        || (!prev.is_ascii_alphabetic() && curr.is_ascii_alphabetic())
        || (!prev.is_ascii_digit() && curr.is_ascii_digit());
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

    #[test]
    fn test_guess_keyword_range() {
        fn guess_range(line: &str, item: &str, expected: (usize, usize)) {
            let keyword_range = get_keyword_range(line, line.len(), false);
            assert_eq!(guess_keyword_range(keyword_range, item, line), expected);
        }

        guess_range("str/tr", "str/trim", (0, 6));
        guess_range("str/tm", "str/trim", (0, 6));
        guess_range("str/", "str/trim", (0, 4));
        guess_range("test/tr", "str/trim", (5, 7));
        guess_range("lib/do", "lib/do-something!", (0, 6));
        guess_range("  ~f", "~foo", (2, 4));
        guess_range("~/.", ".config/", (2, 3));
        guess_range("~/.", "~/.config/", (0, 3));
        guess_range(" is.", "is.array", (1, 4));
        guess_range("'ta", "'tabline'", (0, 3));
        guess_range("guy mon", "guy montag", (4, 7)); // aborts when hitting whitespace
        guess_range("~/.a123", "/.a123456", (1, 7));
    }
}
