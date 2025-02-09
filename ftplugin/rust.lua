vim.lsp.inlay_hint.enable(true)

local utils = require("utils")

local root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]) or "."

-- Must be global so the cargo run process is not per buffer
RunData = {
	win = nil,
	buf = nil,
	system_obj = nil,
	term_channel = nil,
	output = {},
}

local function close_run_win()
	if RunData.win ~= nil then
		vim.api.nvim_win_close(RunData.win, false)
	end

	if RunData.buf ~= nil then
		vim.api.nvim_buf_delete(RunData.buf, { force = true })
	end

	RunData.win = nil
	RunData.buf = nil
end

local function cleanup_run_data(keep_output)
	keep_output = keep_output or false
	close_run_win()
	RunData.system_obj = nil
	if not keep_output then
		RunData.output = {}
	end
	RunData.term_channel = nil
end

local function open_run_output()
	RunData.buf = vim.api.nvim_create_buf(false, true)
	pcall(vim.api.nvim_buf_set_name, RunData.buf, "Cargo Run Output")

	vim.keymap.set("n", "q", close_run_win, { buffer = RunData.buf, nowait = true })
	vim.keymap.set("n", "<esc>", close_run_win, { buffer = RunData.buf, nowait = true })

	local pos = utils.pos_from_screen_percent({ row = 0.10, col = 0.10 })
	local size = utils.size_from_screen_percent({ row = 0.8, col = 0.8 })

	local config = {
		relative = "editor",
		row = pos.row,
		col = pos.col,
		width = size.width,
		height = size.height,
		border = "single",
		style = "minimal",
		title = "Output",
	}
	RunData.win = vim.api.nvim_open_win(RunData.buf, true, config)
	RunData.term_channel = vim.api.nvim_open_term(RunData.buf, {})
	for _, line in ipairs(RunData.output) do
		if line ~= "" then
			vim.api.nvim_chan_send(RunData.term_channel, line .. "\n")
		end
	end

	local line_count = vim.api.nvim_buf_line_count(RunData.buf)
	vim.api.nvim_win_set_cursor(RunData.win, { line_count, 1 })
end

local function on_run_output(_, data)
	if RunData.system_obj == nil or data == nil or data == "" then
		return
	end

	local lines = vim.split(data, "\n", { plain = true, trimempty = true })
	for _, line in ipairs(lines) do
		RunData.output[#RunData.output + 1] = line
	end
end

--- @type fun(out: vim.SystemCompleted)
local function on_run_done(system_obj)
	local lines = vim.split(system_obj.stderr, "\n", { plain = true, trimempty = true })
	for _, line in ipairs(lines) do
		RunData.output[#RunData.output + 1] = line
	end

	if system_obj.code ~= 0 then
		vim.notify("Run failed!", vim.log.levels.ERROR)
	end

	if system_obj.code == 0 then
		vim.notify("Run finished!", vim.log.levels.WARN)
	end

	vim.schedule(function()
		cleanup_run_data(true)
	end)
end

local function cargo_run()
	if RunData.system_obj then
		vim.notify("Stopping running process...")
		RunData.system_obj:kill(15)
		cleanup_run_data()
		return
	end

	vim.notify("Executing Cargo run")
	RunData.system_obj = vim.system(
		{ "cargo", "r" },
		{ cwd = root_dir, stdout = on_run_output, text = true },
		on_run_done
	)
end

--- @type fun(out: vim.SystemCompleted)
local function on_test_done(system_obj)
	if system_obj.code ~= 0 then
		vim.notify("Tests failed!", vim.log.levels.ERROR)
		error(system_obj.stderr)
	else
		local passed = 0
		local failed = 0

		local lines = vim.split(system_obj.stdout, "\n", { trimempty = true })
		for _, line in ipairs(lines) do
			local test_event = vim.json.decode(line, {})
			if test_event.type == "suite" and test_event.event == "ok" then
				passed = passed + test_event.passed
				failed = failed + test_event.failed
			end
		end

		vim.notify("Tests Done: " .. passed .. " passed " .. failed .. " failed!")
	end
end

local function cargo_test()
	vim.notify("Running tests...")
	vim.system(
		{ "cargo", "nextest", "r", "--message-format", "libtest-json" },
		{ cwd = root_dir, env = { ["NEXTEST_EXPERIMENTAL_LIBTEST_JSON"] = "1" } },
		on_test_done
	)
end

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
vim.keymap.set("n", "<leader>cu", cargo_run, { buffer = 0 })
vim.keymap.set("n", "<leader>lr", open_run_output, { buffer = 0 })
vim.keymap.set("n", "<leader>ct", cargo_test, { buffer = 0 })
