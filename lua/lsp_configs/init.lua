local lua_lsp = require("lsp_configs.lua_lsp")
local rust_analyzer = require("lsp_configs.rust_analyser")
local clangd = require("lsp_configs.clangd")
local nixd = require("lsp_configs.nixd")
local omnisharp = require("lsp_configs.omnisharp")

M = {}
M[lua_lsp.filetype] = lua_lsp
M[rust_analyzer.filetype] = rust_analyzer
M[clangd.filetype] = clangd
M[nixd.filetype] = nixd
M[omnisharp.filetype] = omnisharp

return M
