local modules = {
	"cmdwin",
	"keymaps",
	"file_explorer",
	"file_finder",
	"settings",
	"startup",
	"startup.art",
	"statusline",
	"terminal",
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
end

vim.api.nvim_create_user_command("Reload", function()
	CleanupModules()
	LoadModules()
end, {})

LoadModules()
