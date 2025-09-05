#[derive(thiserror::Error, Debug)]
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
    IoError(#[from] std::io::Error),

    #[error("Failed to decode frecency entry: {0}")]
    BincodeDecodeError(#[from] bincode::error::DecodeError),
    #[error("Failed to encode frecency entry: {0}")]
    BincodeEncodeError(#[from] bincode::error::EncodeError),
}

impl From<Error> for mlua::Error {
    fn from(value: Error) -> Self {
        mlua::Error::RuntimeError(value.to_string())
    }
}
