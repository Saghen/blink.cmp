// TODO: refactor this heresy

use crate::frecency::FrecencyTracker;
use crate::keyword;
use crate::lsp_item::LspItem;
use crate::sort::Sort;
use mlua::prelude::*;
use mlua::FromLua;
use mlua::Lua;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::collections::HashSet;

#[derive(Clone)]
pub struct FuzzyOptions {
    match_suffix: bool,
    max_typos: u16,
    use_frecency: bool,
    use_proximity: bool,
    nearby_words: Option<Vec<String>>,
    snippet_score_offset: i32,
    sorts: Option<Vec<Sort>>,
}

impl FromLua for FuzzyOptions {
    fn from_lua(value: LuaValue, _lua: &'_ Lua) -> LuaResult<Self> {
        if let Some(tab) = value.as_table() {
            let match_suffix: bool = tab.get("match_suffix").unwrap_or_default();
            let max_typos: u16 = tab.get("max_typos").unwrap_or_default();
            let use_frecency: bool = tab.get("use_frecency").unwrap_or_default();
            let use_proximity: bool = tab.get("use_proximity").unwrap_or_default();
            let nearby_words: Option<Vec<String>> = tab.get("nearby_words").ok();
            let snippet_score_offset: i32 = tab.get("snippet_score_offset").unwrap_or_default();
            let sorts: Option<Vec<String>> = tab.get("sorts").ok();
            let sorts = sorts
                .map(|sorts| {
                    sorts
                        .iter()
                        .map(|s| s.try_into())
                        .collect::<Result<Vec<_>, _>>()
                })
                .transpose()?;

            Ok(FuzzyOptions {
                match_suffix,
                max_typos,
                use_frecency,
                use_proximity,
                nearby_words,
                snippet_score_offset,
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

fn group_by_needle(
    line: &str,
    cursor_col: usize,
    haystack: &[String],
    match_suffix: bool,
) -> HashMap<String, Vec<(usize, String)>> {
    let mut items_by_needle: HashMap<String, Vec<(usize, String)>> = HashMap::new();
    for (idx, item_text) in haystack.iter().enumerate() {
        let needle = keyword::guess_keyword_from_item(item_text, line, cursor_col, match_suffix);
        let entry = items_by_needle.entry(needle).or_default();
        entry.push((idx, item_text.to_string()));
    }
    items_by_needle
}

pub fn fuzzy(
    line: &str,
    cursor_col: usize,
    haystack: &[LspItem],
    frecency: &FrecencyTracker,
    opts: FuzzyOptions,
) -> (Vec<i32>, Vec<u32>, Vec<bool>) {
    let haystack_labels = haystack
        .iter()
        .map(|s| s.filter_text.clone().unwrap_or(s.label.clone()))
        .collect::<Vec<_>>();
    let options = frizbee::Options {
        max_typos: Some(opts.max_typos),
        sort: false,
        ..Default::default()
    };

    // Items may have different fuzzy matching ranges, so we split them up by needle
    let mut matches = group_by_needle(line, cursor_col, &haystack_labels, opts.match_suffix)
        .into_iter()
        // Match on each needle and combine
        .flat_map(|(needle, haystack)| {
            let mut matches = frizbee::match_list(
                &needle,
                &haystack
                    .iter()
                    .map(|(_, str)| str.as_str())
                    .collect::<Vec<_>>(),
                options,
            );
            for mtch in matches.iter_mut() {
                mtch.index_in_haystack = haystack[mtch.index_in_haystack as usize].0 as u32;
            }
            matches
        })
        .collect::<Vec<_>>();

    // Get the score for each match, adding score_offset, frecency and proximity bonus
    let nearby_words: HashSet<String> = HashSet::from_iter(opts.nearby_words.unwrap_or_default());
    let match_scores = matches
        .iter()
        .map(|mtch| {
            let frecency_score = if opts.use_frecency {
                frecency.get_score(&haystack[mtch.index_in_haystack as usize]) as i32
            } else {
                0
            };
            let nearby_words_score = if opts.use_proximity {
                nearby_words
                    .get(&haystack_labels[mtch.index_in_haystack as usize])
                    .map(|_| 2)
                    .unwrap_or(0)
            } else {
                0
            };
            let mut score_offset = haystack[mtch.index_in_haystack as usize].score_offset;
            // 15 = snippet
            // TODO: use an enum for the kind
            if haystack[mtch.index_in_haystack as usize].kind == 15 {
                score_offset += opts.snippet_score_offset;
            }

            (
                mtch.index_in_haystack,
                (mtch.score as i32) + frecency_score + nearby_words_score + score_offset,
            )
        })
        .collect::<HashMap<_, _>>();

    // Sort by index in haystack
    matches.sort_by_key(|mtch| mtch.index_in_haystack);
    // Sort by user-defined sorts
    if let Some(sorts) = opts.sorts {
        matches.sort_by(|a, b| {
            sorts.iter().fold(Ordering::Equal, |acc, sort| {
                let item_a = &haystack[a.index_in_haystack as usize];
                let item_b = &haystack[b.index_in_haystack as usize];
                match sort {
                    // Reverse ordering
                    Sort::Exact => acc.then(b.exact.cmp(&a.exact)),
                    Sort::Score => acc.then(
                        match_scores[&b.index_in_haystack].cmp(&match_scores[&a.index_in_haystack]),
                    ),
                    // Regular ordering
                    Sort::Kind => acc.then(item_a.kind.cmp(&item_b.kind)),
                    Sort::SortText => acc.then(match (&item_a.sort_text, &item_b.sort_text) {
                        (None, _) | (_, None) => Ordering::Equal,
                        (Some(a), Some(b)) => a.cmp(b),
                    }),
                    Sort::Label => acc.then(Sort::label(item_a, item_b)),
                }
            })
        })
    }

    // Return scores, indices and whether the match is exact
    (
        matches
            .iter()
            .map(|mtch| match_scores[&mtch.index_in_haystack])
            .collect::<Vec<_>>(),
        matches
            .iter()
            .map(|mtch| mtch.index_in_haystack)
            .collect::<Vec<_>>(),
        matches.iter().map(|mtch| mtch.exact).collect::<Vec<_>>(),
    )
}

pub fn fuzzy_matched_indices(
    line: &str,
    cursor_col: usize,
    haystack: &[String],
    match_suffix: bool,
) -> Vec<Vec<usize>> {
    let options = frizbee::Options {
        max_typos: None,
        sort: false,
        ..Default::default()
    };
    let mut matches = group_by_needle(line, cursor_col, haystack, match_suffix)
        .into_iter()
        .flat_map(|(needle, haystack)| {
            let needle = needle.as_str();
            haystack
                .into_iter()
                .map(|(idx, haystack)| {
                    (
                        idx,
                        frizbee::match_indices(needle, haystack, options)
                            .unwrap()
                            .indices,
                    )
                })
                .collect::<Vec<_>>()
        })
        .collect::<Vec<_>>();
    matches.sort_by_key(|mtch| mtch.0);

    matches
        .into_iter()
        .map(|(_, matched_indices)| matched_indices)
        .collect::<Vec<_>>()
}
