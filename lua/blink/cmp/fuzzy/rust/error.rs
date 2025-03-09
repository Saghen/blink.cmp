#[derive(thiserror::Error, Debug)]
#[non_exhaustive]
pub enum Error {
    #[error("Failed to acquire lock for frecency")]
    AcquireFrecencyLock,

    #[error("Failed to acquire lock for items by provider")]
    AcquireItemLock,

    #[error("Attempted to use frecency before initialization")]
    UseFrecencyBeforeInit,

    #[error(
        "Attempted to fuzzy match for provider {provider_id} before setting the provider's items"
    )]
    FuzzyBeforeSetItems { provider_id: String },

    #[error("Failed to create frecency database directory: {0}")]
    CreateDir(#[source] std::io::Error),
    #[error("Failed to open frecency database env: {0}")]
    EnvOpen(#[source] heed::Error),
    #[error("Failed to create frecency database: {0}")]
    DbCreate(#[source] heed::Error),
    #[error("Failed to clear stale readers for frecency database: {0}")]
    DbClearStaleReaders(#[source] heed::Error),

    #[error("Failed to start read transaction for frecency database: {0}")]
    DbStartReadTxn(#[source] heed::Error),
    #[error("Failed to start write transaction for frecency database: {0}")]
    DbStartWriteTxn(#[source] heed::Error),

    #[error("Failed to read from frecency database: {0}")]
    DbRead(#[source] heed::Error),
    #[error("Failed to write to frecency database: {0}")]
    DbWrite(#[source] heed::Error),
    #[error("Failed to commit write transaction to frecency database: {0}")]
    DbCommit(#[source] heed::Error),
}

impl From<Error> for mlua::Error {
    fn from(value: Error) -> Self {
        mlua::Error::RuntimeError(value.to_string())
    }
}
