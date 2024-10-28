use mlua::prelude::*;

#[derive(Debug)]
pub struct LspItem {
    pub label: String,
    pub kind: u32,
    pub score_offset: i32,
    pub source_id: String,
}

impl FromLua for LspItem {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        if let Some(tab) = value.as_table() {
            let label: String = tab.get("label").unwrap_or_default();
            let kind: u32 = tab.get("kind").unwrap_or_default();
            let score_offset: i32 = tab.get("score_offset").unwrap_or(0);
            let source_id: String = tab.get("source_id").unwrap_or_default();

            Ok(LspItem {
                label,
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
