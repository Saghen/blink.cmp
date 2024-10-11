// TODO: refactor this heresy

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
    min_score: u16,
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
        min_score: opts.min_score,
        stable_sort: false,
        ..Default::default()
    };
    let mut matches = frizbee::match_list(&needle, &haystack_labels, options);

    // Sort by scores
    // TODO: boost exact matches
    let match_scores = matches
        .iter()
        .map(|mtch| {
            (mtch.score as i32)
                + frecency.get_score(&haystack[mtch.index_in_haystack]) as i32
                + nearby_words
                    .get(&haystack[mtch.index_in_haystack].label)
                    .map(|_| 2)
                    .unwrap_or(0)
                + haystack[mtch.index_in_haystack].score_offset.unwrap_or(0)
        })
        .collect::<Vec<_>>();

    // Find the highest score and filter out matches that are unreasonably lower than it
    let max_score = matches.iter().map(|mtch| mtch.score).max().unwrap_or(0);
    let secondary_min_score = max_score.max(16) - 16;
    matches = matches
        .into_iter()
        .filter(|mtch| mtch.score >= secondary_min_score)
        .collect::<Vec<_>>();

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
        .take(opts.max_items)
        .collect::<Vec<_>>()
}
