local modules = {
	"keymaps",
	"logs",
	"settings",
	"startup",
	"startup.art",
	"ui",
	"ui.cmdwin",
	"ui.messages",
	"ui.select",
	"ui.popup",
	"utils",
	"file_explorer",
	"file_finder",
	"format",
	"lsp",
	"lsp.snippets",
	"quick_fix",
	"sessions",
	"statusline",
	"tabline",
	"terminal",
	"workspace_grep",
}

_G.win_size = { row = vim.api.nvim_win_get_height(0), col = vim.api.nvim_win_get_width(0) }

local ft_plugins = {
	"rust",
	"nix",
}

function LoadModules()
	for _, mod_name in ipairs(modules) do
		local mod = require(mod_name)
		if type(mod) == "table" and mod.Init ~= nil then
			mod.Init()
		end
	end
end

function CleanupModules()
	for _, mod_name in ipairs(modules) do
		local mod = require(mod_name)
		if type(mod) == "table" and mod.Cleanup ~= nil then
			mod.Cleanup()
		end
		package.loaded[mod_name] = nil
	end

	for _, plugin in ipairs(ft_plugins) do
		package.loaded[plugin] = nil
	end
end

vim.api.nvim_create_user_command("Reload", function()
	vim.notify("Reloading config...")
	CleanupModules()
	LoadModules()
end, {})

LoadModules()
