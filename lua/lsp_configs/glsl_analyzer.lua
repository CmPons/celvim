M = {}

M.filetype = { "glsl" }
M.file_ext = { "*.vert", "*.frag", "*.geom", "*.comp", "*.tesc", "*.tese", "*.glsl" }
M.config = {
	name = "glsl_analyzer",
	cmd = { "glsl_analyzer" },
}

return M
