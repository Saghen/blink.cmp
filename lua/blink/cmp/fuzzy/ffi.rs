#![feature(test)]

mod frecency;
mod fuzzy;

pub mod extern_ffi {
    use crate::frecency::FrecencyTracker;
    use crate::fuzzy::{self, FuzzyOptions, LspItem};
    use lazy_static::lazy_static;
    use regex::Regex;
    use std::collections::HashSet;
    use std::sync::RwLock;

    lazy_static! {
        static ref REGEX: Regex = Regex::new(r"[A-Za-z][A-Za-z0-9_\\-]{2,32}").unwrap();
        static ref FRECENCY: RwLock<Option<FrecencyTracker>> = RwLock::new(None);
    }

    pub fn init_db(db_path: String) -> bool {
        let mut frecency = FRECENCY.write().unwrap();
        if frecency.is_some() {
            return false;
        }
        *frecency = Some(FrecencyTracker::new(&db_path));
        true
    }

    pub fn destroy_db() -> bool {
        // todo: there should be a way to get rid of old locks
        // since a crash would result in a leak
        let frecency = FRECENCY.write().unwrap();
        drop(frecency);

        let mut frecency = FRECENCY.write().unwrap();
        *frecency = None;
        true
    }

    pub fn access(item: LspItem) -> bool {
        let mut frecency_handle = FRECENCY.write().unwrap();
        let frecency = frecency_handle.as_mut().unwrap();
        frecency.access(&item).unwrap();
        true
    }

    pub fn fuzzy(
        needle: String,
        haystack_labels: Vec<String>,
        haystack_kinds: Vec<u32>,
        haystack_score_offsets: Vec<i32>,
        haystack_sources: Vec<String>,
        opts: FuzzyOptions,
    ) -> Vec<u32> {
        let mut frecency_handle = FRECENCY.write().unwrap();
        let frecency = frecency_handle.as_mut().unwrap();

        let haystack = (0..haystack_labels.len())
            .map(|i| LspItem {
                label: haystack_labels[i].clone(),
                sort_text: None,
                filter_text: None,
                kind: haystack_kinds[i],
                score_offset: Some(haystack_score_offsets[i]),
                source: haystack_sources[i].clone(),
            })
            .collect::<Vec<_>>();
        fuzzy::fuzzy(needle, haystack, frecency, opts)
            .into_iter()
            .map(|i| i as u32)
            .collect()
    }

    pub fn get_words(text: String) -> Vec<String> {
        REGEX
            .find_iter(&text)
            .map(|m| m.as_str().to_string())
            .collect::<HashSet<String>>()
            .into_iter()
            .collect()
    }
}

include!(concat!(env!("OUT_DIR"), "/ffi.rs"));
