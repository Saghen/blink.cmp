use std::collections::HashMap;
use std::fs::OpenOptions;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use bincode::{Decode, Encode};
use blake3::Hash;

use crate::error::Error;

const ENTRY_SIZE: usize = 64;
// ~0.5 after 1 minute (x = 60)
// ~0.2 after 1 hour (x = 3600)
// ~0.1 after 1 day (x = 86400)
// ~0.06 after 1 week (x = 604800)
const DECAY_CONSTANT: f64 = 0.2;

#[derive(Decode, Encode, Clone, Debug)]
struct FrecencyEntry {
    hash: [u8; 32],
    timestamp: u64,
    score: f64,
}

/// Frecency database using fixed-sized entries and atomic writes for lock-free cross-process access
/// algorithm:     new_score = score * (1 / (1 + (current_time - score_time)) ^ decay_constant)
/// or more mathy: f(x) = (1 / (1 + (x - x0)) ^ a)
/// https://github.com/Saghen/blink.cmp/issues/258
pub struct FrecencyDB {
    path: PathBuf,
    cache: HashMap<[u8; 32], (u64, FrecencyEntry)>, // hash -> (file_position, entry)
}

impl FrecencyDB {
    pub fn new(path: &PathBuf) -> Result<Self, Error> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(false)
            .open(path)?;

        let mut db = FrecencyDB {
            path: path.clone(),
            cache: HashMap::new(),
        };

        // Load cache on initialization
        db.reload_cache()?;

        Ok(db)
    }

    /// Gets the score for a given item
    pub fn get_score(&self, key: &Hash) -> Option<f64> {
        self.get(key).map(|(timestamp, score)| {
            let current_timestamp = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|timestamp| timestamp.as_secs())
                .unwrap_or(0);

            score * (1. / (1. + (current_timestamp - timestamp) as f64)).powf(DECAY_CONSTANT)
        })
    }

    /// Accesses a given item
    pub fn access(&mut self, key: &Hash) -> Result<(), Error> {
        let score = self.get_score(&key).unwrap_or(0.0);

        let current_timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|timestamp| timestamp.as_secs())
            .unwrap_or(0);

        self.put(key, current_timestamp, score + 4.)?;

        Ok(())
    }

    /// Gets an entry from the cache, if it exists
    fn get(&self, hash: &Hash) -> Option<(u64, f64)> {
        self.cache
            .get(hash.as_bytes())
            .map(|(_, entry)| (entry.timestamp, entry.score))
    }

    // Inserts an item in the filesystem, updating in-place if it already exists
    fn put(&mut self, hash: &Hash, timestamp: u64, score: f64) -> Result<(), Error> {
        // First, reload cache to ensure we have latest state
        self.reload_cache()?;

        let entry = FrecencyEntry {
            hash: *hash.as_bytes(),
            timestamp,
            score,
        };

        // Check cache for existing position
        let position = self.cache.get(hash.as_bytes()).map(|(pos, _)| *pos);

        // Prepare entry buffer
        let mut serialized_entry = [0u8; ENTRY_SIZE];
        bincode::encode_into_slice(&entry, &mut serialized_entry, bincode::config::standard())?;

        let mut file = OpenOptions::new().write(true).read(true).open(&self.path)?;

        // Update filesystem
        let final_position = if let Some(pos) = position {
            // Update in place
            file.seek(SeekFrom::Start(pos))?;
            file.write_all(&serialized_entry)?;
            pos
        } else {
            // Append new entry
            file.seek(SeekFrom::End(0))?;
            let pos = file.stream_position()?;
            file.write_all(&serialized_entry)?;
            pos
        };

        // Update cache
        self.cache.insert(entry.hash, (final_position, entry));

        // fsync the data
        file.sync_data()?;

        Ok(())
    }

    fn reload_cache(&mut self) -> Result<(), Error> {
        let mut file = OpenOptions::new().read(true).open(&self.path)?;

        let mut new_cache = HashMap::new();
        let mut buffer = [0u8; ENTRY_SIZE];
        let mut position = 0u64;

        loop {
            file.seek(SeekFrom::Start(position))?;
            match file.read_exact(&mut buffer) {
                Ok(_) => {
                    let entry: FrecencyEntry =
                        bincode::decode_from_slice(&buffer, bincode::config::standard())?.0;
                    new_cache.insert(entry.hash, (position, entry));
                    position += ENTRY_SIZE as u64;
                }
                Err(_) => break,
            }
        }

        self.cache = new_cache;

        Ok(())
    }
}
