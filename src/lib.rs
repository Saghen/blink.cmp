use crate::frecency::FrecencyTracker;
use crate::fuzzy::FuzzyOptions;
use crate::lsp_item::LspItem;
use lazy_static::lazy_static;
use mlua::prelude::*;
use regex::Regex;
use std::collections::HashSet;
use std::sync::RwLock;

mod frecency;
mod fuzzy;
mod lsp_item;

lazy_static! {
    static ref REGEX: Regex = Regex::new(r"[A-Za-z][A-Za-z0-9_\\-]{2,32}").unwrap();
    static ref FRECENCY: RwLock<Option<FrecencyTracker>> = RwLock::new(None);
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

pub fn fuzzy(
    _lua: &Lua,
    (needle, haystack, opts): (String, Vec<LspItem>, FuzzyOptions),
) -> LuaResult<Vec<u32>> {
    let mut frecency_handle = FRECENCY.write().map_err(|_| {
        mlua::Error::RuntimeError("Failed to acquire lock for frecency".to_string())
    })?;
    let frecency = frecency_handle.as_mut().ok_or_else(|| {
        mlua::Error::RuntimeError("Attempted to use frencecy before initialization".to_string())
    })?;

    Ok(fuzzy::fuzzy(needle, haystack, frecency, opts)
        .into_iter()
        .map(|i| i as u32)
        .collect())
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
        .collect::<HashSet<String>>()
        .into_iter()
        .collect())
}

// NOTE: skip_memory_check greatly improves performance
// https://github.com/mlua-rs/mlua/issues/318
#[mlua::lua_module(skip_memory_check)]
fn blink_cmp_fuzzy(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
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
