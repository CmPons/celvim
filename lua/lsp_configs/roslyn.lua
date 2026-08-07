local M = {}

local function root_dir()
	local root = vim.fs.find(function(name)
		return name:match("%.slnx?$") ~= nil or name:match("%.csproj$") ~= nil or name:match("%.uproject$") ~= nil
	end, { upward = true })[1]

	return root and vim.fs.dirname(root) or vim.uv.cwd()
end

local function find_file(root, pattern)
	return vim.fs.find(function(name)
		return name:match(pattern) ~= nil
	end, { path = root, type = "file", limit = 1 })[1]
end

local function cmd()
	if vim.env.ROSLYN_LSP ~= nil and vim.env.ROSLYN_LSP ~= "" then
		return vim.env.ROSLYN_LSP
	end

	return vim.fn.has("win32") == 1 and "roslyn-language-server.cmd" or "roslyn-language-server"
end

local function open_workspace(client)
	local root = client.config.root_dir
	local solution = find_file(root, "%.slnx?$")
	if solution ~= nil then
		client:notify("solution/open", {
			solution = vim.uri_from_fname(solution),
		})
		return
	end

	local project = find_file(root, "%.csproj$")
	if project ~= nil then
		client:notify("project/open", {
			projects = { vim.uri_from_fname(project) },
		})
	end
end

M.filetype = "cs"
M.file_ext = "*.cs"
M.config = {
	name = "roslyn",
	cmd = {
		cmd(),
		"--logLevel",
		"Information",
		"--extensionLogDirectory",
		vim.fs.joinpath(vim.fn.stdpath("data"), "roslyn", "logs"),
		"--stdio",
	},
	root_dir = root_dir(),
	capabilities = {
		textDocument = {
			diagnostic = {
				dynamicRegistration = true,
			},
		},
	},
	on_init = open_workspace,
}

return M
