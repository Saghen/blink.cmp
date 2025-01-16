use crate::error::Error;
use crate::lsp_item::LspItem;
use heed::{types::*, EnvFlags};
use heed::{Database, Env, EnvOpenOptions};
use serde::{Deserialize, Serialize};
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Clone, Serialize, Deserialize)]
struct CompletionItemKey {
    label: String,
    kind: u32,
    source_id: String,
}

impl From<&LspItem> for CompletionItemKey {
    fn from(item: &LspItem) -> Self {
        Self {
            label: item.label.clone(),
            kind: item.kind,
            source_id: item.source_id.clone(),
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
    pub fn new(db_path: &str, use_unsafe_no_lock: bool) -> Result<Self, Error> {
        fs::create_dir_all(db_path).map_err(Error::CreateDir)?;
        let env = unsafe {
            let mut opts = EnvOpenOptions::new();
            if use_unsafe_no_lock {
                opts.flags(EnvFlags::NO_LOCK | EnvFlags::NO_SYNC | EnvFlags::NO_META_SYNC);
            }
            opts.open(db_path).map_err(Error::EnvOpen)?
        };
        env.clear_stale_readers()
            .map_err(Error::DbClearStaleReaders)?;

        // we will open the default unnamed database
        let mut wtxn = env.write_txn().map_err(Error::DbStartWriteTxn)?;
        let db = env
            .create_database(&mut wtxn, None)
            .map_err(Error::DbCreate)?;

        let access_thresholds = [
            (1., 1000 * 60 * 2),             // 2 minutes
            (0.2, 1000 * 60 * 60),           // 1 hour
            (0.1, 1000 * 60 * 60 * 24),      // 1 day
            (0.05, 1000 * 60 * 60 * 24 * 7), // 1 week
        ]
        .to_vec();

        Ok(FrecencyTracker {
            env: env.clone(),
            db,
            access_thresholds,
        })
    }

    fn get_accesses(&self, item: &LspItem) -> Result<Option<Vec<u64>>, Error> {
        let rtxn = self.env.read_txn().map_err(Error::DbStartReadTxn)?;
        self.db
            .get(&rtxn, &CompletionItemKey::from(item))
            .map_err(Error::DbRead)
    }

    fn get_now(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
    }

    pub fn access(&self, item: &LspItem) -> Result<(), Error> {
        let mut wtxn = self.env.write_txn().map_err(Error::DbStartWriteTxn)?;

        let mut accesses = self.get_accesses(item)?.unwrap_or_default();
        accesses.push(self.get_now());

        self.db
            .put(&mut wtxn, &CompletionItemKey::from(item), &accesses)
            .map_err(Error::DbWrite)?;

        wtxn.commit().map_err(Error::DbCommit)?;

        Ok(())
    }

    pub fn get_score(&self, item: &LspItem) -> i64 {
        let accesses = self.get_accesses(item).unwrap_or(None).unwrap_or_default();
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
