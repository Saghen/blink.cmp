#![feature(test)]

mod frecency;

pub mod extern_ffi {
    use crate::frecency::FrecencyTracker;
    use fzrs::{match_list, Options};
    use lazy_static::lazy_static;
    use lua_marshalling::LuaMarshalling;
    use regex::Regex;
    use std::cmp::Reverse;
    use std::collections::HashSet;
    use std::sync::RwLock;

    lazy_static! {
        static ref REGEX: Regex = Regex::new(r"[A-Za-z][A-Za-z0-9]{2,50}").unwrap();
        static ref FRECENCY: RwLock<Option<FrecencyTracker>> = RwLock::new(None);
    }

    struct Item {
        index: u32,
        score: u32,
    }

    pub fn init_db(db_path: String) -> bool {
        let mut frecency = FRECENCY.write().unwrap();
        if frecency.is_some() {
            return false;
        }
        *frecency = Some(FrecencyTracker::new(&db_path));
        true
    }

    pub fn fuzzy(
        needle: String,
        haystack: Vec<String>,
        haystack_score_offsets: Vec<i32>,
        nearby_words: Vec<String>,
        max_items: u32,
    ) -> Vec<u32> {
        let frecency_handle = FRECENCY.read().unwrap();
        let frecency = frecency_handle.as_ref().unwrap();

        let nearby_words = nearby_words
            .iter()
            .map(|s| s.as_str())
            .collect::<HashSet<_>>();

        // Fuzzy match with fzrs
        let haystack = haystack.iter().map(|s| s.as_str()).collect::<Vec<_>>();
        let options = Options {
            min_score: (needle.len() * 3) as u16,
            stable_sort: false,
            ..Default::default()
        };
        let mut matches = match_list(&needle, &haystack, options);

        // Sort matches by fzrs score + frecency score + proximity score
        matches.sort_by_cached_key(|m| {
            Reverse(
                (m.score as i64)
                    + frecency.get_score(haystack[m.index])
                    + nearby_words.get(&haystack[m.index]).map(|_| 2).unwrap_or(0)
                    + haystack_score_offsets[m.index] as i64,
            )
        });

        matches
            .iter()
            .map(|m| m.index as u32)
            .take(max_items as usize)
            .collect::<Vec<_>>()
    }

    pub fn access(item: String) -> bool {
        let mut frecency_handle = FRECENCY.write().unwrap();
        let mut frecency = frecency_handle.as_mut().unwrap();
        frecency.access(item.as_str()).unwrap();
        true
    }

    pub fn get_lines_words(lines: String) -> Vec<String> {
        REGEX
            .find_iter(&lines)
            .map(|m| m.as_str().to_string())
            .collect::<HashSet<String>>()
            .into_iter()
            .collect()
    }
}

include!(concat!(env!("OUT_DIR"), "/ffi.rs"));

#[cfg(test)]
mod tests {
    extern crate test;
    use super::*;
    use test::Bencher;

    #[test]
    fn test_fuzzy() {
        let prompt = "e".to_string();
        let items = vec![
            "enable24".to_string(),
            "asd".to_string(),
            "wowowowe".to_string(),
        ];
        let indices = extern_ffi::fuzzy(prompt, items);
        assert_eq!(indices, vec![0, 2]);
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let items: Vec<String> = (0..1000).map(|num| num.to_string()).collect();
        b.iter(|| {
            let prompt = "4".to_string();
            let _indices = extern_ffi::fuzzy(prompt.clone(), items.clone());
        });
    }
}
