use mlua::prelude::*;

#[derive(Debug)]
pub struct LspItem {
    pub label: String,
    pub filter_text: Option<String>,
    pub kind: u32,
    pub score_offset: i32,
    pub source_id: String,
}

impl FromLua for LspItem {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        if let Some(tab) = value.as_table() {
            let label = tab.get("label").unwrap_or_default();
            let filter_text = tab.get("filter_text").ok();
            let kind = tab.get("kind").unwrap_or_default();
            let score_offset = tab.get("score_offset").unwrap_or(0);
            let source_id = tab.get("source_id").unwrap_or_default();

            Ok(LspItem {
                label,
                filter_text,
                kind,
                score_offset,
                source_id,
            })
        } else {
            Err(mlua::Error::FromLuaConversionError {
                from: "LuaValue",
                to: "LspItem".to_string(),
                message: None,
            })
        }
    }
}
