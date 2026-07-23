local lua_lsp = require("lsp_configs.lua_lsp")
local rust_analyzer = require("lsp_configs.rust_analyser")
local clangd = require("lsp_configs.clangd")
local nixd = require("lsp_configs.nixd")
local omnisharp = require("lsp_configs.omnisharp")
local ts_ls = require("lsp_configs.ts_ls")
local js_ls = require("lsp_configs.js_ls")
local glsl_analyzer = require("lsp_configs.glsl_analyzer")

M = {}
M[lua_lsp.filetype] = lua_lsp
M[rust_analyzer.filetype] = rust_analyzer
M[clangd.filetype] = clangd
M[nixd.filetype] = nixd
M[omnisharp.filetype] = omnisharp
M[ts_ls.filetype] = ts_ls
M[js_ls.filetype] = js_ls
M[glsl_analyzer.filetype] = glsl_analyzer

return M
