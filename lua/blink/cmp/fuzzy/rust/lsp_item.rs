use mlua::prelude::*;

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
#[repr(u32)]
#[allow(dead_code)]
pub enum CompletionItemKind {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
}

#[derive(Debug, Clone)]
pub struct LspItem {
    pub label: String,
    pub filter_text: Option<String>,
    pub sort_text: Option<String>,
    pub insert_text: Option<String>,
    pub kind: u32,
    pub score_offset: i32,
    pub source_id: String,
}

impl FromLua for LspItem {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        if let Some(tab) = value.as_table() {
            let label = tab
                .get::<mlua::String>("label")
                .map(|s| s.to_string_lossy())
                .unwrap_or_default();
            let filter_text = tab
                .get::<mlua::String>("filterText")
                .ok()
                .map(|s| s.to_string_lossy());
            let sort_text = tab
                .get::<mlua::String>("sortText")
                .ok()
                .map(|s| s.to_string_lossy());
            let insert_text = tab
                .get::<LuaTable>("textEdit")
                .and_then(|text_edit| text_edit.get::<mlua::String>("newText"))
                .ok()
                .or_else(|| tab.get::<mlua::String>("insertText").ok())
                .map(|s| s.to_string_lossy());
            let kind = tab.get("kind").unwrap_or_default();
            let score_offset = tab.get("score_offset").unwrap_or(0);
            let source_id = tab.get("source_id").unwrap_or_default();

            Ok(LspItem {
                label,
                filter_text,
                sort_text,
                insert_text,
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
