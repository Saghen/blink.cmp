use crate::lsp_item::LspItem;
use heed::types::*;
use heed::{Database, Env, EnvOpenOptions};
use mlua::Result as LuaResult;
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
    pub fn new(db_path: &str) -> LuaResult<Self> {
        fs::create_dir_all(db_path).map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to create frecency database directory: ".to_string() + &err.to_string(),
            )
        })?;
        let env = unsafe {
            EnvOpenOptions::new().open(db_path).map_err(|err| {
                mlua::Error::RuntimeError(
                    "Failed to open frecency database: ".to_string() + &err.to_string(),
                )
            })?
        };
        env.clear_stale_readers().map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to clear stale readers for frecency database: ".to_string()
                    + &err.to_string(),
            )
        })?;

        // we will open the default unnamed database
        let mut wtxn = env.write_txn().map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to open write transaction for frecency database: ".to_string()
                    + &err.to_string(),
            )
        })?;
        let db = env.create_database(&mut wtxn, None).map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to create frecency database: ".to_string() + &err.to_string(),
            )
        })?;

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

    fn get_accesses(&self, item: &LspItem) -> LuaResult<Option<Vec<u64>>> {
        let rtxn = self.env.read_txn().map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to start read transaction for frecency database: ".to_string()
                    + &err.to_string(),
            )
        })?;
        self.db
            .get(&rtxn, &CompletionItemKey::from(item))
            .map_err(|err| {
                mlua::Error::RuntimeError(
                    "Failed to read from frecency database: ".to_string() + &err.to_string(),
                )
            })
    }

    fn get_now(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
    }

    pub fn access(&mut self, item: &LspItem) -> LuaResult<()> {
        let mut wtxn = self.env.write_txn().map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to start write transaction for frecency database: ".to_string()
                    + &err.to_string(),
            )
        })?;

        let mut accesses = self.get_accesses(item)?.unwrap_or_default();
        accesses.push(self.get_now());

        self.db
            .put(&mut wtxn, &CompletionItemKey::from(item), &accesses)
            .map_err(|err| {
                mlua::Error::RuntimeError(
                    "Failed to write to frecency database: ".to_string() + &err.to_string(),
                )
            })?;

        wtxn.commit().map_err(|err| {
            mlua::Error::RuntimeError(
                "Failed to commit write transaction for frecency database: ".to_string()
                    + &err.to_string(),
            )
        })?;

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
