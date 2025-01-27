-- require("rust.tests")
--
vim.lsp.inlay_hint.enable(true)

local root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]) or "."

--- @type fun(out: vim.SystemCompleted)
local function on_build_done(system_obj)
	if system_obj.code ~= 0 then
		vim.notify("Build failed!", vim.log.levels.ERROR)
		error(system_obj.stderr)
	else
		vim.notify("Build done!", vim.log.levels.INFO)
		info(system_obj.stderr)
	end
end

local function cargo_build()
	vim.notify("Compiling...")
	vim.system({ "cargo", "build" }, { cwd = root_dir }, on_build_done)
end

vim.keymap.set("n", "<leader>cc", cargo_build, { buffer = 0 })
