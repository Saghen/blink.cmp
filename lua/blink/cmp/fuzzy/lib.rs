use crate::frecency::FrecencyTracker;
use crate::fuzzy::FuzzyOptions;
use crate::lsp_item::LspItem;
use lazy_static::lazy_static;
use mlua::prelude::*;
use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::sync::RwLock;

mod frecency;
mod fuzzy;
mod lsp_item;

lazy_static! {
    static ref REGEX: Regex = Regex::new(r"\p{L}[\p{L}0-9_\\-]{2,}").unwrap();
    static ref FRECENCY: RwLock<Option<FrecencyTracker>> = RwLock::new(None);
    static ref HAYSTACKS_BY_PROVIDER: RwLock<HashMap<String, Vec<LspItem>>> =
        RwLock::new(HashMap::new());
}

pub fn init_db(_: &Lua, db_path: String) -> LuaResult<bool> {
    let mut frecency = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    if frecency.is_some() {
        return Ok(false);
    }
    *frecency = Some(FrecencyTracker::new(&db_path)?);
    Ok(true)
}

pub fn destroy_db(_: &Lua, _: ()) -> LuaResult<bool> {
    let frecency = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    drop(frecency);

    let mut frecency = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    *frecency = None;

    Ok(true)
}

pub fn access(_: &Lua, item: LspItem) -> LuaResult<bool> {
    let mut frecency_handle = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    let frecency = frecency_handle.as_mut().ok_or_else(|| {
        mlua::Error::RuntimeError("Attempted to use frencecy before initialization".to_string())
    })?;
    frecency.access(&item)?;
    Ok(true)
}

pub fn set_provider_items(
    _: &Lua,
    (provider_id, items): (String, Vec<LspItem>),
) -> LuaResult<bool> {
    let mut items_by_provider = HAYSTACKS_BY_PROVIDER.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for items by provider".to_string())
    })?;
    items_by_provider.insert(provider_id, items);
    Ok(true)
}

pub fn fuzzy(
    _lua: &Lua,
    (needle, provider_id, opts): (String, String, FuzzyOptions),
) -> LuaResult<(Vec<i32>, Vec<u32>)> {
    let mut frecency_handle = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    let frecency = frecency_handle.as_mut().ok_or_else(|| {
        mlua::Error::RuntimeError("Attempted to use frencecy before initialization".to_string())
    })?;

    let haystacks_by_provider = HAYSTACKS_BY_PROVIDER.read().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for items by provider".to_string())
    })?;
    let haystack = haystacks_by_provider.get(&provider_id).ok_or_else(|| {
        mlua::Error::RuntimeError(format!(
            "Attempted to fuzzy match for provider {} before setting the provider's items",
            provider_id
        ))
    })?;

    Ok(fuzzy::fuzzy(needle, haystack, frecency, opts))
}

pub fn fuzzy_matched_indices(
    _lua: &Lua,
    (needle, haystack): (String, Vec<String>),
) -> LuaResult<Vec<Vec<usize>>> {
    Ok(frizbee::match_list_for_matched_indices(
        &needle,
        &haystack.iter().map(|s| s.as_str()).collect::<Vec<_>>(),
    ))
}

pub fn get_words(_: &Lua, text: String) -> LuaResult<Vec<String>> {
    Ok(REGEX
        .find_iter(&text)
        .map(|m| m.as_str().to_string())
        .filter(|s| s.len() < 512)
        .collect::<HashSet<String>>()
        .into_iter()
        .collect())
}

// NOTE: skip_memory_check greatly improves performance
// https://github.com/mlua-rs/mlua/issues/318
#[mlua::lua_module(skip_memory_check)]
fn blink_cmp_fuzzy(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "set_provider_items",
        lua.create_function(set_provider_items)?,
    )?;
    exports.set("fuzzy", lua.create_function(fuzzy)?)?;
    exports.set(
        "fuzzy_matched_indices",
        lua.create_function(fuzzy_matched_indices)?,
    )?;
    exports.set("get_words", lua.create_function(get_words)?)?;
    exports.set("init_db", lua.create_function(init_db)?)?;
    exports.set("destroy_db", lua.create_function(destroy_db)?)?;
    exports.set("access", lua.create_function(access)?)?;
    Ok(exports)
}
