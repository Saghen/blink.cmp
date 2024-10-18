use crate::frecency::FrecencyTracker;
use crate::fuzzy::{FuzzyOptions, LspItem};
use lazy_static::lazy_static;
use mlua::prelude::*;
use regex::Regex;
use std::collections::HashSet;
use std::sync::RwLock;

mod frecency;
mod fuzzy;

lazy_static! {
    static ref REGEX: Regex = Regex::new(r"[A-Za-z][A-Za-z0-9_\\-]{2,32}").unwrap();
    static ref FRECENCY: RwLock<Option<FrecencyTracker>> = RwLock::new(None);
}

pub fn init_db(_: &Lua, db_path: String) -> LuaResult<bool> {
    let mut frecency = FRECENCY.write().unwrap();
    if frecency.is_some() {
        return Ok(false);
    }
    *frecency = Some(FrecencyTracker::new(&db_path));
    Ok(true)
}

pub fn destroy_db(_: &Lua, _: ()) -> LuaResult<bool> {
    // todo: there should be a way to get rid of old locks
    // since a crash would result in a leak
    let frecency = FRECENCY.write().unwrap();
    drop(frecency);
    let mut frecency = FRECENCY.write().unwrap();
    *frecency = None;
    Ok(true)
}

pub fn access(_: &Lua, item: LspItem) -> LuaResult<bool> {
    let mut frecency_handle = FRECENCY.write().unwrap();
    let frecency = frecency_handle.as_mut().unwrap();
    frecency.access(&item).unwrap();
    Ok(true)
}

pub fn fuzzy(
    _lua: &Lua,
    (needle, haystack, opts): (String, Vec<LspItem>, FuzzyOptions),
) -> LuaResult<Vec<u32>> {
    let mut frecency_handle = FRECENCY.write().unwrap();
    let frecency = frecency_handle.as_mut().unwrap();

    Ok(fuzzy::fuzzy(needle, haystack, frecency, opts)
        .into_iter()
        .map(|i| i as u32)
        .collect())
}

pub fn get_words(_: &Lua, text: String) -> LuaResult<Vec<String>> {
    Ok(REGEX
        .find_iter(&text)
        .map(|m| m.as_str().to_string())
        .collect::<HashSet<String>>()
        .into_iter()
        .collect())
}

#[mlua::lua_module]
fn blink_cmp_fuzzy_rust(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("fuzzy", lua.create_function(fuzzy)?)?;
    exports.set("get_words", lua.create_function(get_words)?)?;
    exports.set("init_db", lua.create_function(init_db)?)?;
    exports.set("destroy_db", lua.create_function(destroy_db)?)?;
    exports.set("access", lua.create_function(access)?)?;
    Ok(exports)
}
