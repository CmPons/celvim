local rust_snippets = require("lsp.snippet_defs.rust")

M = {}
M[rust_snippets.filetype] = rust_snippets.snippets

return M
