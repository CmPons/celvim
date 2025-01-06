local lua_lsp = require("lsp_configs.lua_lsp")
local rust_analyzer = require("lsp_configs.rust_analyser")

M = {}
M[lua_lsp.filetype] = lua_lsp
M[rust_analyzer.filetype] = rust_analyzer

return M
