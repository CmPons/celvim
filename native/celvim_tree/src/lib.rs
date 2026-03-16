use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use ignore::WalkBuilder;
use ignore::WalkState;
use mlua::prelude::*;

enum TreeNode {
    File {
        name: String,
    },
    Directory {
        name: String,
        children: BTreeMap<String, TreeNode>,
    },
}

impl TreeNode {
    fn new_dir(name: impl Into<String>) -> Self {
        TreeNode::Directory {
            name: name.into(),
            children: BTreeMap::new(),
        }
    }

    fn insert_path(&mut self, components: &[&str]) {
        let TreeNode::Directory { children, .. } = self else {
            return;
        };

        match components {
            [] => {}
            [file] => {
                children
                    .entry(file.to_string())
                    .or_insert_with(|| TreeNode::File {
                        name: file.to_string(),
                    });
            }
            [dir, rest @ ..] => {
                let child = children
                    .entry(dir.to_string())
                    .or_insert_with(|| TreeNode::new_dir(*dir));
                child.insert_path(rest);
            }
        }
    }

    fn into_lua_table(self, lua: &Lua) -> LuaResult<LuaTable> {
        let table = lua.create_table()?;

        match self {
            TreeNode::File { name } => {
                table.set("type", "file")?;
                table.set("name", name)?;
            }
            TreeNode::Directory { name, children } => {
                table.set("type", "directory")?;
                table.set("name", name)?;

                let contents = lua.create_table()?;
                let mut idx = 1;

                // Dirs first
                let mut dirs = Vec::new();
                let mut files = Vec::new();
                for (_, child) in children {
                    match &child {
                        TreeNode::Directory { .. } => dirs.push(child),
                        TreeNode::File { .. } => files.push(child),
                    }
                }

                for dir in dirs {
                    contents.set(idx, dir.into_lua_table(lua)?)?;
                    idx += 1;
                }
                for file in files {
                    contents.set(idx, file.into_lua_table(lua)?)?;
                    idx += 1;
                }

                table.set("contents", contents)?;
            }
        }

        Ok(table)
    }
}

fn walk_tree(root: &Path) -> TreeNode {
    let paths: Mutex<Vec<PathBuf>> = Mutex::new(Vec::new());

    // Use ignore's parallel walker — spawns threads across all cores
    let walker = WalkBuilder::new(root)
        .git_ignore(true)
        .git_global(true)
        .git_exclude(true)
        .hidden(false)
        .filter_entry(|entry| {
            // Skip .git directory but allow other dotfiles
            !(entry.file_type().is_some_and(|ft| ft.is_dir())
                && entry.file_name() == ".git")
        })
        .threads(num_cpus())
        .build_parallel();

    walker.run(|| {
        Box::new(|entry| {
            let Ok(entry) = entry else {
                return WalkState::Continue;
            };

            if entry.file_type().is_some_and(|ft| ft.is_file()) {
                if let Ok(rel) = entry.path().strip_prefix(root) {
                    paths.lock().unwrap().push(rel.to_path_buf());
                }
            }

            WalkState::Continue
        })
    });

    let paths = paths.into_inner().unwrap();
    let mut tree = TreeNode::new_dir(".");

    for path in &paths {
        let components: Vec<&str> = path
            .components()
            .filter_map(|c| c.as_os_str().to_str())
            .collect();
        tree.insert_path(&components);
    }

    tree
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}

fn build_tree(lua: &Lua, path: Option<String>) -> LuaResult<LuaTable> {
    let root = match path {
        Some(p) => PathBuf::from(p),
        None => std::env::current_dir().map_err(LuaError::external)?,
    };

    let tree = walk_tree(&root);
    let result = lua.create_table()?;
    result.set(1, tree.into_lua_table(lua)?)?;
    Ok(result)
}

#[mlua::lua_module]
fn celvim_tree(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "build",
        lua.create_function(|lua, path: Option<String>| build_tree(lua, path))?,
    )?;
    Ok(exports)
}
