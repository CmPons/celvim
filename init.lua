local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
	require("profile").instrument_autocmds()
	if should_profile:lower():match("^start") then
		require("profile").start("*")
	else
		require("profile").instrument("*")
	end
end

local function toggle_profile()
	local prof = require("profile")
	if prof.is_recording() then
		prof.stop()
		vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
			if filename then
				prof.export(filename)
				vim.notify(string.format("Wrote %s", filename))
			end
		end)
	else
		prof.start("*")
	end
end
vim.keymap.set("", "<f2>", toggle_profile)

local modules = {
	"cmdwin",
	"keymaps",
	"file_explorer",
	"file_finder",
	"lsp",
	"logs",
	"settings",
	"startup",
	"startup.art",
	"statusline",
	"tabline",
	"terminal",
	"workspace_grep",
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
