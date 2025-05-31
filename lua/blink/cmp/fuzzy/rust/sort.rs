use std::cmp::Ordering;

use crate::lsp_item::LspItem;

#[derive(Debug, Clone, Copy)]
pub enum Sort {
    Exact,
    Score,
    Kind,
    SortText,
    Label,
}

impl TryFrom<&String> for Sort {
    type Error = mlua::Error;

    fn try_from(s: &String) -> Result<Self, Self::Error> {
        match s.as_str() {
            "exact" => Ok(Sort::Exact),
            "score" => Ok(Sort::Score),
            "kind" => Ok(Sort::Kind),
            "sort_text" => Ok(Sort::SortText),
            "label" => Ok(Sort::Label),
            _ => Err(mlua::Error::FromLuaConversionError {
                from: "string",
                to: "Sort".to_string(),
                message: Some(format!(
                    "Invalid sort: {}. Expected one of: exact, score, kind, sort_text, label",
                    s
                )),
            }),
        }
    }
}

/// Swaps the case of a single character (byte) at index i in string s
fn swap_case(s: &str, i: usize) -> u8 {
    let byte = s.as_bytes()[i];
    match byte {
        65..=90 => byte + 32,  // uppercase A-Z -> lowercase
        97..=122 => byte - 32, // lowercase a-z -> uppercase
        _ => byte,             // non-alphabetic characters
    }
}

impl Sort {
    pub fn label(a: &LspItem, b: &LspItem) -> Ordering {
        // prefer foo_bar over _foo_bar
        let entry1_under = a.label.find(|c: char| c != '_').unwrap_or(a.label.len());
        let entry2_under = b.label.find(|c: char| c != '_').unwrap_or(b.label.len());

        match entry1_under.cmp(&entry2_under) {
            Ordering::Greater => return Ordering::Greater,
            Ordering::Less => return Ordering::Less,
            Ordering::Equal => {}
        }

        // prefer "a" over "A" and "a" over "b"
        // Compare characters one by one with case flipping
        let min_len = a.label.len().min(b.label.len());
        for i in 0..min_len {
            let char_a = swap_case(&a.label, i);
            let char_b = swap_case(&b.label, i);

            match char_a.cmp(&char_b) {
                Ordering::Equal => continue,
                other => return other,
            }
        }

        a.label.len().cmp(&b.label.len())
    }
}
