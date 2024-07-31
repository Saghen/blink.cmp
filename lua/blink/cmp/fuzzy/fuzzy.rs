use crate::frecency::FrecencyTracker;
use lua_marshalling::LuaMarshalling;
use serde::{Deserialize, Serialize};
use std::cmp::Reverse;
use std::collections::HashSet;

#[derive(Clone, Serialize, Deserialize, LuaMarshalling)]
pub struct LspItem {
    pub label: String,
    #[serde(rename = "sortText")]
    pub sort_text: Option<String>,
    #[serde(rename = "filterText")]
    pub filter_text: Option<String>,
    pub kind: u32,
    pub score_offset: Option<i32>,
    pub source: String,
}

#[derive(Clone, LuaMarshalling)]
pub struct MatchedLspItem {
    label: String,
    kind: u32,
    index: u32,
    score: i32,
}

#[derive(LuaMarshalling)]
pub struct FuzzyOptions {
    use_frecency: bool,
    nearby_words: Option<Vec<String>>,
    max_items: usize,
    sorts: Vec<String>,
}

pub fn fuzzy(
    needle: String,
    haystack: Vec<LspItem>,
    frecency: &FrecencyTracker,
    opts: FuzzyOptions,
) -> Vec<usize> {
    let nearby_words: HashSet<String> = HashSet::from_iter(opts.nearby_words.unwrap_or_default());

    // Fuzzy match with fzrs
    let haystack_labels = haystack
        .iter()
        .map(|s| s.label.as_str())
        .collect::<Vec<_>>();
    let options = frizbee::Options {
        min_score: 0,
        stable_sort: false,
        ..Default::default()
    };
    let mut matches = frizbee::match_list(&needle, &haystack_labels, options);

    // Sort by scores
    let match_scores = matches
        .iter()
        .map(|mtch| {
            (mtch.score as i32)
                + frecency.get_score(&haystack[mtch.index]) as i32
                + nearby_words
                    .get(&haystack[mtch.index].label)
                    .map(|_| 2)
                    .unwrap_or(0)
                + haystack[mtch.index].score_offset.unwrap_or(0)
        })
        .collect::<Vec<_>>();
    matches.sort_by_cached_key(|mtch| Reverse(match_scores[mtch.index]));

    // Grab the top N matches
    let mut match_indices = matches
        .iter()
        .map(|mtch| mtch.index)
        .take(opts.max_items)
        .collect::<Vec<_>>();

    // Sort matches by sort criteria
    for sort in opts.sorts.iter() {
        match sort.as_str() {
            "kind" => {
                match_indices.sort_by_key(|idx| haystack[*idx].kind);
            }
            "score" => {
                match_indices.sort_by_key(|idx| Reverse(match_scores[*idx]));
            }
            "label" => {
                match_indices.sort_by_key(|idx| haystack[*idx].label.clone());
            }
            _ => {}
        }
    }

    match_indices
}
