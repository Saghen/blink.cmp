use std::fs;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

use heed::types::*;
use heed::{Database, Env, EnvOpenOptions};
use serde::{Deserialize, Serialize};

pub struct FrecencyTracker {
    env: Env,
    db: Database<Str, SerdeBincode<Vec<u64>>>,
    access_thresholds: Vec<(f64, u64)>,
}

impl FrecencyTracker {
    pub fn new(db_path: &str) -> Self {
        fs::create_dir_all(db_path);
        let env = unsafe { EnvOpenOptions::new().open(db_path).unwrap() };

        // we will open the default unnamed database
        let mut wtxn = env.write_txn().unwrap();
        let db: Database<Str, SerdeBincode<Vec<u64>>> =
            env.create_database(&mut wtxn, None).unwrap();

        let access_thresholds = [
            (2., 1000 * 60 * 2),            // 2 minutes
            (1., 1000 * 60 * 5),            // 5 minutes
            (0.5, 1000 * 60 * 30),          // 2 hours
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

    fn get_accesses(&self, item: &str) -> Option<Vec<u64>> {
        let rtxn = self
            .env
            .read_txn()
            .expect("Failed to start read transaction");
        self.db
            .get(&rtxn, item)
            .expect("Failed to read from database")
    }

    fn get_now(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
    }

    pub fn access(&mut self, item: &str) -> Result<(), heed::Error> {
        let mut wtxn = self.env.write_txn()?;
        let mut accesses = self.get_accesses(item).unwrap_or_else(Vec::new);
        accesses.push(self.get_now());
        self.db.put(&mut wtxn, item, &accesses)?;
        wtxn.commit()?;
        Ok(())
    }

    pub fn get_score(&self, item: &str) -> i64 {
        let accesses = self.get_accesses(item).unwrap_or_else(Vec::new);
        let now = self.get_now();
        let mut score = 0.0;
        'outer: for access in &accesses {
            let duration_since = now - access;
            for (rank, threshold_duration_since) in &self.access_thresholds {
                if duration_since < *threshold_duration_since {
                    score += rank;
                }
                continue 'outer;
            }
        }
        (score * accesses.len() as f64).min(5.) as i64
    }
}
