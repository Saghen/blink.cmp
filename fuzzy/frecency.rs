use crate::fuzzy::LspItem;
use heed::types::*;
use heed::{Database, Env, EnvOpenOptions};
use serde::{Deserialize, Serialize};
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Clone, Serialize, Deserialize)]
struct CompletionItemKey {
    label: String,
    kind: u32,
    source: String,
}

impl From<&LspItem> for CompletionItemKey {
    fn from(item: &LspItem) -> Self {
        Self {
            label: item.label.clone(),
            kind: item.kind,
            source: item.source.clone(),
        }
    }
}

#[derive(Debug)]
pub struct FrecencyTracker {
    env: Env,
    db: Database<SerdeBincode<CompletionItemKey>, SerdeBincode<Vec<u64>>>,
    access_thresholds: Vec<(f64, u64)>,
}

impl FrecencyTracker {
    pub fn new(db_path: &str) -> Self {
        fs::create_dir_all(db_path).unwrap();
        let env = unsafe { EnvOpenOptions::new().open(db_path).unwrap() };
        env.clear_stale_readers().unwrap();

        // we will open the default unnamed database
        let mut wtxn = env.write_txn().unwrap();
        let db = env.create_database(&mut wtxn, None).unwrap();

        let access_thresholds = [
            (1., 1000 * 60 * 2),            // 2 minutes
            (0.5, 1000 * 60 * 60),          // 1 hour
            (0.2, 1000 * 60 * 60 * 24),     // 1 day
            (0.1, 1000 * 60 * 60 * 24 * 7), // 1 week
        ]
        .to_vec();

        FrecencyTracker {
            env: env.clone(),
            db,
            access_thresholds,
        }
    }

    fn get_accesses(&self, item: &LspItem) -> Option<Vec<u64>> {
        let rtxn = self
            .env
            .read_txn()
            .expect("Failed to start read transaction");
        self.db
            .get(&rtxn, &CompletionItemKey::from(item))
            .expect("Failed to read from database")
    }

    fn get_now(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
    }

    pub fn access(&mut self, item: &LspItem) -> Result<(), heed::Error> {
        let mut wtxn = self.env.write_txn()?;
        let mut accesses = self.get_accesses(item).unwrap_or_default();
        accesses.push(self.get_now());
        self.db
            .put(&mut wtxn, &CompletionItemKey::from(item), &accesses)?;
        wtxn.commit()?;
        Ok(())
    }

    pub fn get_score(&self, item: &LspItem) -> i64 {
        let accesses = self.get_accesses(item).unwrap_or_default();
        let now = self.get_now();
        let mut score = 0.0;
        'outer: for access in &accesses {
            let duration_since = now - access;
            for (rank, threshold_duration_since) in &self.access_thresholds {
                if duration_since < *threshold_duration_since {
                    score += rank;
                    continue 'outer;
                }
            }
        }
        score.min(4.) as i64
    }
}
