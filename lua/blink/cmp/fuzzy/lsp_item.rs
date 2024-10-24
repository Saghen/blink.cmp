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

// #[derive(Debug)]
// pub struct LspItem<'lua> {
//     table: LuaTable<'lua>,
//     pub label: OnceCell<String>,
//     pub sort_text: OnceCell<Option<String>>,
//     pub filter_text: OnceCell<String>,
//     pub kind: OnceCell<u32>,
//     pub score_offset: OnceCell<i32>,
//     pub source_id: OnceCell<String>,
// }
//
// impl LspItem<'_> {
//     pub fn label(&self) -> String {
//         self.label
//             .get_or_init(|| self.table.get::<_, String>("label").unwrap_or_default())
//             .to_owned()
//     }
//     pub fn sort_text(&self) -> Option<String> {
//         self.sort_text
//             .get_or_init(|| self.table.get("sortText").ok())
//             .to_owned()
//     }
//     pub fn filter_text(&self) -> String {
//         self.filter_text
//             .get_or_init(|| self.table.get("filterText").unwrap_or(self.label()))
//             .to_owned()
//     }
//     pub fn kind(&self) -> u32 {
//         self.kind
//             .get_or_init(|| self.table.get("kind").unwrap_or_default())
//             .to_owned()
//     }
//     pub fn score_offset(&self) -> i32 {
//         self.score_offset
//             .get_or_init(|| self.table.get("score_offset").unwrap_or(0))
//             .to_owned()
//     }
//     pub fn source_id(&self) -> String {
//         self.source_id
//             .get_or_init(|| self.table.get("source_id").unwrap_or_default())
//             .to_owned()
//     }
// }
//
// impl<'lua> FromLua<'lua> for LspItem<'lua> {
//     fn from_lua(value: LuaValue<'lua>, _lua: &'lua Lua) -> LuaResult<Self> {
//         match value {
//             LuaValue::Table(tab) => Ok(LspItem {
//                 table: tab,
//                 label: OnceCell::new(),
//                 sort_text: OnceCell::new(),
//                 filter_text: OnceCell::new(),
//                 kind: OnceCell::new(),
//                 score_offset: OnceCell::new(),
//                 source_id: OnceCell::new(),
//             }),
//             _ => Err(mlua::Error::FromLuaConversionError {
//                 from: "LuaValue",
//                 to: "LspItem",
//                 message: None,
//             }),
//         }
//     }
// }
