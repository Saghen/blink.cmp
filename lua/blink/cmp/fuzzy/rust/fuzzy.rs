// TODO: refactor this heresy

use crate::frecency::FrecencyTracker;
use crate::keyword;
use crate::lsp_item::LspItem;
use mlua::prelude::*;
use mlua::FromLua;
use mlua::Lua;
use std::collections::HashMap;
use std::collections::HashSet;

#[derive(Clone, Hash)]
pub struct FuzzyOptions {
    match_suffix: bool,
    max_typos: u16,
    use_frecency: bool,
    use_proximity: bool,
    nearby_words: Option<Vec<String>>,
    snippet_score_offset: i32,
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

            Ok(FuzzyOptions {
                match_suffix,
                max_typos,
                use_frecency,
                use_proximity,
                nearby_words,
                snippet_score_offset,
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
    #[cfg(feature = "x86_fuzzy")]
    {
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

        matches.sort_by_key(|mtch| mtch.index_in_haystack);

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

                (mtch.score as i32) + frecency_score + nearby_words_score + score_offset
            })
            .collect::<Vec<_>>();

        // Return scores, indices and whether the match is exact
        (
            match_scores,
            matches
                .iter()
                .map(|mtch| mtch.index_in_haystack)
                .collect::<Vec<_>>(),
            matches.iter().map(|mtch| mtch.exact).collect::<Vec<_>>(),
        )
    }

    #[cfg(feature = "arm_fuzzy")]
    {
        use fuzzy_matcher::skim::SkimMatcherV2;
        use fuzzy_matcher::FuzzyMatcher;

        let matcher = SkimMatcherV2::default();
        let haystack_labels = haystack
            .iter()
            .map(|s| s.filter_text.clone().unwrap_or(s.label.clone()))
            .collect::<Vec<_>>();

        // Group items by needle
        let items_by_needle = group_by_needle(line, cursor_col, &haystack_labels, opts.match_suffix);
        
        let mut results: Vec<(i32, u32, bool)> = Vec::new();

        // For each needle, find matches
        for (needle, items) in items_by_needle {
            for (idx, haystack_str) in items {
                // Use fuzzy-matcher to get score and indices
                if let Some((score, _indices)) = matcher.fuzzy_indices(&haystack_str, &needle) {
                    let item_idx = idx as u32;
                    let is_exact = haystack_str == needle;
                    
                    // Apply same scoring adjustments as x86 version
                    let frecency_score = if opts.use_frecency {
                        frecency.get_score(&haystack[idx]) as i32
                    } else {
                        0
                    };

                    let nearby_words: HashSet<String> = 
                        HashSet::from_iter(opts.nearby_words.clone().unwrap_or_default());
                    
                    let nearby_words_score = if opts.use_proximity {
                        nearby_words
                            .get(&haystack_labels[idx])
                            .map(|_| 2)
                            .unwrap_or(0)
                    } else {
                        0
                    };

                    let mut score_offset = haystack[idx].score_offset;
                    // 15 = snippet
                    if haystack[idx].kind == 15 {
                        score_offset += opts.snippet_score_offset;
                    }

                    // Convert i64 score to i32
                    let final_score = (score as i32) + frecency_score + nearby_words_score + score_offset;
                    results.push((final_score, item_idx, is_exact));
                }
            }
        }

        // Sort by index to match x86 behavior
        results.sort_by_key(|(_, idx, _)| *idx);

        // Unzip the results into three vectors
        let scores: Vec<i32> = results.iter().map(|(score, _, _)| *score).collect();
        let indices: Vec<u32> = results.iter().map(|(_, idx, _)| *idx).collect();
        let exact: Vec<bool> = results.iter().map(|(_, _, exact)| *exact).collect();

        (scores, indices, exact)
    }
}

pub fn fuzzy_matched_indices(
    line: &str,
    cursor_col: usize,
    haystack: &[String],
    match_suffix: bool,
) -> Vec<Vec<usize>> {
    #[cfg(feature = "x86_fuzzy")]
    {
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

    #[cfg(feature = "arm_fuzzy")]
    {
        use fuzzy_matcher::skim::SkimMatcherV2;
        use fuzzy_matcher::FuzzyMatcher;

        let matcher = SkimMatcherV2::default();
        
        // Group items by needle
        let items_by_needle = group_by_needle(line, cursor_col, haystack, match_suffix);
        
        let mut matches: Vec<(usize, Vec<usize>)> = Vec::new();
        
        // For each needle, find matches
        for (needle, items) in items_by_needle {
            for (idx, haystack_str) in items {
                // Use fuzzy-matcher to get indices
                if let Some((_, indices)) = matcher.fuzzy_indices(&haystack_str, &needle) {
                    matches.push((idx, indices));
                } else {
                    // If no match found, return empty indices
                    matches.push((idx, vec![]));
                }
            }
        }
        
        // Sort by original index
        matches.sort_by_key(|(idx, _)| *idx);
        
        // Return just the indices
        matches
            .into_iter()
            .map(|(_, indices)| indices)
            .collect::<Vec<_>>()
    }
}
