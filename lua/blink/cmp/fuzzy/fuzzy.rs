// TODO: refactor this heresy

use crate::frecency::FrecencyTracker;
use crate::lsp_item::LspItem;
use mlua::prelude::*;
use mlua::FromLua;
use mlua::Lua;
use std::cmp::Reverse;
use std::collections::HashSet;

#[derive(Clone, Hash)]
pub struct FuzzyOptions {
    use_typo_resistance: bool,
    use_frecency: bool,
    use_proximity: bool,
    nearby_words: Option<Vec<String>>,
    min_score: u16,
    max_items: u32,
    sorts: Vec<String>,
}

impl FromLua for FuzzyOptions {
    fn from_lua(value: LuaValue, _lua: &'_ Lua) -> LuaResult<Self> {
        if let Some(tab) = value.as_table() {
            let use_typo_resistance: bool = tab.get("use_typo_resistance").unwrap_or_default();
            let use_frecency: bool = tab.get("use_frecency").unwrap_or_default();
            let use_proximity: bool = tab.get("use_proximity").unwrap_or_default();
            let nearby_words: Option<Vec<String>> = tab.get("nearby_words").ok();
            let min_score: u16 = tab.get("min_score").unwrap_or_default();
            let max_items: u32 = tab.get("max_items").unwrap_or_default();
            let sorts: Vec<String> = tab.get("sorts").unwrap_or_default();

            Ok(FuzzyOptions {
                use_typo_resistance,
                use_frecency,
                use_proximity,
                nearby_words,
                min_score,
                max_items,
                sorts,
            })
        } else {
            Err(mlua::Error::FromLuaConversionError {
                from: "LuaValue",
                to: "FuzzyOptions".to_string(),
                message: None,
            })
        }
    }
}

pub fn fuzzy(
    needle: String,
    haystack: Vec<LspItem>,
    frecency: &FrecencyTracker,
    opts: FuzzyOptions,
) -> Vec<usize> {
    let nearby_words: HashSet<String> = HashSet::from_iter(opts.nearby_words.unwrap_or_default());
    let haystack_labels = haystack.iter().map(|s| s.label.clone()).collect::<Vec<_>>();

    // Fuzzy match with fzrs
    let options = frizbee::Options {
        prefilter: !opts.use_typo_resistance,
        min_score: opts.min_score,
        stable_sort: false,
        ..Default::default()
    };
    let mut matches = frizbee::match_list(
        &needle,
        &haystack_labels
            .iter()
            .map(|s| s.as_str())
            .collect::<Vec<_>>(),
        options,
    );

    // Sort by scores
    let match_scores = matches
        .iter()
        .map(|mtch| {
            let frecency_score = if opts.use_frecency {
                frecency.get_score(&haystack[mtch.index_in_haystack]) as i32
            } else {
                0
            };
            let nearby_words_score = if opts.use_proximity {
                nearby_words
                    .get(&haystack_labels[mtch.index_in_haystack])
                    .map(|_| 2)
                    .unwrap_or(0)
            } else {
                0
            };
            let score_offset = haystack[mtch.index_in_haystack].score_offset;

            (mtch.score as i32) + frecency_score + nearby_words_score + score_offset
        })
        .collect::<Vec<_>>();

    // Find the highest score and filter out matches that are unreasonably lower than it
    if opts.use_typo_resistance {
        let max_score = matches.iter().map(|mtch| mtch.score).max().unwrap_or(0);
        let secondary_min_score = max_score.max(16) - 16;
        matches = matches
            .into_iter()
            .filter(|mtch| mtch.score >= secondary_min_score)
            .collect::<Vec<_>>();
    }

    // Sort matches by sort criteria
    for sort in opts.sorts.iter() {
        match sort.as_str() {
            "kind" => {
                matches.sort_by_key(|mtch| haystack[mtch.index_in_haystack].kind);
            }
            "score" => {
                matches.sort_by_cached_key(|mtch| Reverse(match_scores[mtch.index]));
            }
            "label" => {
                matches.sort_by(|a, b| {
                    let label_a = &haystack[a.index_in_haystack].label;
                    let label_b = &haystack[b.index_in_haystack].label;

                    // Put anything with an underscore at the end
                    match (label_a.starts_with('_'), label_b.starts_with('_')) {
                        (true, false) => std::cmp::Ordering::Greater,
                        (false, true) => std::cmp::Ordering::Less,
                        _ => label_a.cmp(label_b),
                    }
                });
            }
            _ => {}
        }
    }

    // Grab the top N matches and return the indices
    matches
        .iter()
        .map(|mtch| mtch.index_in_haystack)
        .take(opts.max_items as usize)
        .collect::<Vec<_>>()
}
