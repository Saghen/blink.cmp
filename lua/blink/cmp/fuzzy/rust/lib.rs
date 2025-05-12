use crate::error::Error;
use crate::frecency::FrecencyTracker;
use crate::fuzzy::FuzzyOptions;
use crate::lsp_item::LspItem;
use lsp_item::CompletionItemKind;
use mlua::prelude::*;
use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::sync::{LazyLock, RwLock};

mod error;
mod frecency;
mod fuzzy;
mod keyword;
mod lsp_item;

static REGEX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"[\p{L}_][\p{L}0-9_\\-]{2,}").unwrap());
static FRECENCY: LazyLock<RwLock<Option<FrecencyTracker>>> = LazyLock::new(|| RwLock::new(None));
static HAYSTACKS_BY_PROVIDER: LazyLock<RwLock<HashMap<String, Vec<LspItem>>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));

pub fn init_db(_: &Lua, (db_path, use_unsafe_no_lock): (String, bool)) -> LuaResult<bool> {
    let mut frecency = FRECENCY.write().map_err(|_| Error::AcquireFrecencyLock)?;
    if frecency.is_some() {
        return Ok(false);
    }
    *frecency = Some(FrecencyTracker::new(&db_path, use_unsafe_no_lock)?);
    Ok(true)
}

pub fn destroy_db(_: &Lua, _: ()) -> LuaResult<bool> {
    let frecency = FRECENCY.write().map_err(|_| Error::AcquireFrecencyLock)?;
    drop(frecency);

    let mut frecency = FRECENCY.write().map_err(|_| Error::AcquireFrecencyLock)?;
    *frecency = None;

    Ok(true)
}

pub fn access(_: &Lua, item: LspItem) -> LuaResult<bool> {
    let mut frecency = FRECENCY.write().map_err(|_| Error::AcquireFrecencyLock)?;
    let frecency = frecency.as_mut().ok_or(Error::UseFrecencyBeforeInit)?;
    frecency.access(&item)?;
    Ok(true)
}

pub fn set_provider_items(
    _: &Lua,
    (provider_id, items): (String, Vec<LspItem>),
) -> LuaResult<bool> {
    HAYSTACKS_BY_PROVIDER
        .write()
        .map_err(|_| Error::AcquireItemLock)?
        .insert(provider_id, items);
    Ok(true)
}

pub fn fuzzy(
    _lua: &Lua,
    (line, cursor_col, provider_id, opts): (mlua::String, usize, String, FuzzyOptions),
) -> LuaResult<(Vec<i32>, Vec<u32>, Vec<bool>)> {
    let frecency = FRECENCY.read().map_err(|_| Error::AcquireFrecencyLock)?;
    let frecency = frecency.as_ref().ok_or(Error::UseFrecencyBeforeInit)?;

    let haystacks_by_provider = HAYSTACKS_BY_PROVIDER
        .read()
        .map_err(|_| Error::AcquireItemLock)?;
    let haystack = haystacks_by_provider
        .get(&provider_id)
        .ok_or(Error::FuzzyBeforeSetItems { provider_id })?;

    Ok(fuzzy::fuzzy(
        &line.to_string_lossy(),
        cursor_col,
        haystack,
        frecency,
        opts,
    ))
}

pub fn fuzzy_matched_indices(
    _lua: &Lua,
    (line, cursor_col, haystack, match_suffix): (mlua::String, usize, Vec<mlua::String>, bool),
) -> LuaResult<Vec<Vec<usize>>> {
    Ok(fuzzy::fuzzy_matched_indices(
        &line.to_string_lossy(),
        cursor_col,
        &haystack
            .iter()
            .map(|s| s.to_string_lossy())
            .collect::<Vec<_>>(),
        match_suffix,
    ))
}

pub fn get_keyword_range(
    _lua: &Lua,
    (line, col, match_suffix): (mlua::String, usize, bool),
) -> LuaResult<(usize, usize)> {
    Ok(keyword::get_keyword_range(
        &line.to_string_lossy(),
        col,
        match_suffix,
    ))
}

pub fn guess_edit_range(
    _lua: &Lua,
    (item, line, cursor_col, match_suffix): (LspItem, mlua::String, usize, bool),
) -> LuaResult<(usize, usize)> {
    let line_str = line.to_string_lossy();

    let label_edit_range =
        keyword::guess_keyword_range_from_item(&item.label, &line_str, cursor_col, match_suffix);
    let filter_text_edit_range = item
        .filter_text
        .as_ref()
        .map(|filter_text| {
            keyword::guess_keyword_range_from_item(filter_text, &line_str, cursor_col, match_suffix)
        })
        .unwrap_or(label_edit_range);
    let insert_text_edit_range = item
        .insert_text
        .as_ref()
        .map(|insert_text| {
            keyword::guess_keyword_range_from_item(insert_text, &line_str, cursor_col, match_suffix)
        })
        .unwrap_or(filter_text_edit_range);

    // Prefer the insert text, then filter text, then label ranges for non-snippets
    if item.kind != CompletionItemKind::Snippet as u32 {
        return Ok(insert_text_edit_range);
    }

    // HACK: In the lazydev.nvim case, the label is the whole module like `blink.cmp.fuzzy`
    // but the `insertText` is just `fuzzy` when you've already typed `blink.cmp.`.
    // But in the snippets case, the label could be completed unrelated to the insertText so we
    // should use the label range.
    //
    // TODO: What about using the filterText range and ignoring label?

    // Take the max range prioritizing the start index first and the end index second
    // When comparing tuples (start, end), Rust compares the first element first,
    // and only if those are equal, it compares the second element
    Ok([
        label_edit_range,
        filter_text_edit_range,
        insert_text_edit_range,
    ]
    .iter()
    // Transform to (start, -end) to find minimum start and maximum end
    .min_by_key(|&(start, end)| (start, std::cmp::Reverse(end)))
    .copied()
    .unwrap_or((0, 0)))
}

pub fn get_words(_: &Lua, text: mlua::String) -> LuaResult<Vec<String>> {
    Ok(REGEX
        .find_iter(&text.to_string_lossy())
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
    exports.set("init_db", lua.create_function(init_db)?)?;
    exports.set("destroy_db", lua.create_function(destroy_db)?)?;
    exports.set("access", lua.create_function(access)?)?;
    exports.set(
        "set_provider_items",
        lua.create_function(set_provider_items)?,
    )?;
    exports.set("fuzzy", lua.create_function(fuzzy)?)?;
    exports.set(
        "fuzzy_matched_indices",
        lua.create_function(fuzzy_matched_indices)?,
    )?;
    exports.set("get_keyword_range", lua.create_function(get_keyword_range)?)?;
    exports.set("guess_edit_range", lua.create_function(guess_edit_range)?)?;
    exports.set("get_words", lua.create_function(get_words)?)?;
    Ok(exports)
}
