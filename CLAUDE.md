# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Celvim is a plugin-free Neovim configuration written entirely using built-in Neovim APIs. It provides a complete IDE-like experience without external plugins, focusing on LSP integration, custom UI components, and development tooling.

## Development Setup

This project uses Nix flakes for reproducible development environments:

```bash
# Enter development shell with all dependencies
nix develop

# Or run Neovim directly
nix develop github:CmPons/celvim
```

The flake provides:
- Neovim with required LSPs (lua-language-server, rust-analyzer, clangd, nixd, omnisharp-roslyn)
- Development tools (fzf, tree, stylua, nixfmt, shfmt)
- Sets `NVIM_APPNAME=celvim` environment variable

## Core Architecture

### Module System
The configuration uses a modular architecture defined in `init.lua`:
- Each module exports `Init()` and optional `Cleanup()` functions
- Modules are loaded sequentially at startup
- Use `:Reload` command during development to hot-reload all modules

### Key Modules
- `lsp`: LSP client configuration with auto-formatting and completion
- `file_finder`: fzf-based file search with preview
- `file_explorer`: Custom file browser
- `workspace_grep`: Project-wide search functionality
- `ui/*`: Custom UI components (popup, select, messages, cmdwin)
- `quick_fix`: Diagnostic integration
- `keymaps`: Centralized keymap management with cleanup

### LSP Configuration
- Per-filetype LSP setup in `lua/lsp_configs/`
- Supports: Lua, Rust, C/C++, Nix, C#
- Auto-formatting on save with fallback to `formatprg`
- Custom auto-completion triggers on `(`, `,`, `<` characters
- Hover documentation on function calls

## Common Development Tasks

### Reloading Configuration
Use `:Reload` command to reload all modules without restarting Neovim.

### Testing
The project includes a testing specification (`celvim_testing_spec.md`) for plenary.nvim-based testing:
- Test infrastructure should use `tests/minimal_init.lua`
- Mock LSP server capabilities in `tests/mock_server.lua`
- Focus on testing custom LSP logic and autocomplete triggers

### Debugging Rust Tests
Use the provided script for debugging Rust unit tests:
```bash
./scripts/debug_unit_test.sh <test_name> <working_directory>
```

## Key Features

### File Operations
- `<leader>ff` or `<space><space>`: Fuzzy file finder with bat preview
- File explorer with creation, deletion, and navigation
- Tab-based buffer management

### LSP Integration
- `gr`: Find references
- `gd`: Go to definition  
- `gi`: Go to implementation
- `<leader>cr`: Rename symbol
- `<leader>ca`: Code actions
- `[e]`/`]e`: Navigate errors
- `[w]`/`]w`: Navigate warnings

### Custom UI
- Popup windows for selections and messages
- Custom statusline with LSP status
- Terminal integration with proper naming
- Notification system

### Auto-completion
- Bracket/quote auto-pairing with smart deletion
- UUID insertion with `<C-u>` in insert mode
- LSP-based completion triggered by specific characters
- Snippet expansion system

## Code Patterns

### Module Structure
```lua
local M = {}

M.Init = function()
    -- Module initialization
end

M.Cleanup = function()
    -- Cleanup autocmds, keymaps, etc.
end

return M
```

### Keymap Management
Use `keymaps.set_keymap()` instead of `vim.keymap.set()` to ensure proper cleanup during reload.

### LSP Client Configuration
Each language has its own config in `lua/lsp_configs/` with:
- `filetype`: Target filetype
- `file_ext`: File extension pattern
- `config`: LSP client configuration

## File Structure Notes

- `init.lua`: Main entry point with module loading
- `lua/`: All Lua modules
- `ftplugin/`: Filetype-specific configurations
- `syntax/`: Custom syntax files (Rust)
- `pack/third_party/start/`: External dependencies (plenary.nvim)
- `scripts/`: Development and debugging utilities

## Dependencies

External tools required (provided by Nix flake):
- `fzf`: File finder backend
- `bat`: File preview in finder
- Language servers and formatters per `flake.nix`

The configuration is designed to work without any Neovim plugins, relying entirely on built-in APIs and external command-line tools.
