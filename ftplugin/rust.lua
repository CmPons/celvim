vim.lsp.inlay_hint.enable(true)

local utils = require("utils")
local root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]) or "."
local test_namespace = vim.api.nvim_create_namespace("cargo_test")

local function resolve_test_location(test_full_name, error_message, diagnostics_table, ns)
	local func_name = test_full_name:match("([^:]+)$")
	if not func_name then
		return
	end

	local clients = vim.lsp.get_clients({ name = "rust-lsp" })
	if #clients == 0 then
		return
	end
	local client = clients[1]

	client.request("workspace/symbol", { query = func_name }, function(err, result)
		if err or not result or vim.tbl_isempty(result) then
			return
		end

		local target_symbol = nil
		for _, symbol in ipairs(result) do
			if symbol.name == func_name then
				target_symbol = symbol
				break
			end
		end

		if not target_symbol then
			return
		end

		local uri = target_symbol.location.uri
		local bufnr = vim.uri_to_bufnr(uri)

		if not vim.api.nvim_buf_is_loaded(bufnr) then
			vim.fn.bufload(bufnr)
		end

		if not diagnostics_table[bufnr] then
			diagnostics_table[bufnr] = {}
		end

		local lnum = target_symbol.location.range.start.line

		table.insert(diagnostics_table[bufnr], {
			lnum = lnum,
			col = 0,
			severity = vim.diagnostic.severity.ERROR,
			message = error_message,
			source = "cargo-test (result)",
		})

		vim.schedule(function()
			vim.diagnostic.set(ns, bufnr, diagnostics_table[bufnr])
		end)
	end, 0) -- 0 = current buffer context, or pass a specific bufnr if known
end

--- @type fun(out: vim.SystemCompleted)
local function on_test_done(system_obj)
	-- Clear previous test diagnostics
	vim.diagnostic.reset(test_namespace)

	local passed = 0
	local failed = 0
	local diagnostics_by_file = {}

	-- Parse JSON output
	local lines = vim.split(system_obj.stdout, "\n", { trimempty = true })
	for _, line in ipairs(lines) do
		local ok, test_event = pcall(vim.json.decode, line)

		if ok and test_event then
			-- Count results
			if test_event.type == "suite" and test_event.event == "ok" then
				passed = passed + test_event.passed
			end

			if test_event.type == "test" and test_event.event == "failed" then
				failed = failed + 1
				local output = test_event.stdout or ""
				local found_panic_location = false

				for out_line in output:gmatch("[^\r\n]+") do
					local file, lnum = out_line:match("(%S+%.rs):(%d+):")

					if file and lnum then
						found_panic_location = true
						local bufnr = vim.fn.bufnr(file)
						if bufnr == -1 then
							bufnr = vim.fn.bufadd(file)
						end

						if not diagnostics_by_file[bufnr] then
							diagnostics_by_file[bufnr] = {}
						end
						local output_lines = vim.split(output, "\n", { plain = true, trimempty = true })

						-- Remove "Panicked at line" and NOTE backtrace line
						local trimmed_message = table.concat(vim.list_slice(output_lines, 2, #output_lines - 1), "\n")

						table.insert(diagnostics_by_file[bufnr], {
							lnum = tonumber(lnum) - 1,
							col = 0,
							severity = vim.diagnostic.severity.ERROR,
							message = trimmed_message,
							source = "cargo-test",
						})
						break
					end
				end

				if not found_panic_location then
					resolve_test_location(test_event.name, output, diagnostics_by_file, test_namespace)
				end
			end
		end
	end

	-- Set diagnostics for sync results (Panic failures found via Regex)
	for bufnr, diagnostics in pairs(diagnostics_by_file) do
		vim.diagnostic.set(test_namespace, bufnr, diagnostics)
	end

	local notify_level = vim.log.levels.INFO
	if system_obj.code ~= 0 then
		notify_level = vim.log.levels.ERROR
		print(system_obj.stdout)
		print(system_obj.stderr)
	end

	vim.notify("Tests done: " .. "passed - " .. passed .. " failed - " .. failed, notify_level)
end

local function cargo_test()
	vim.notify("Running tests...")
	vim.system(
		{ "cargo", "nextest", "r", "--message-format", "libtest-json" },
		{ cwd = root_dir, env = { ["NEXTEST_EXPERIMENTAL_LIBTEST_JSON"] = "1" } },
		function(out)
			vim.schedule(function()
				on_test_done(out)
			end)
		end
	)
end

-- Must be global so the cargo run process is not per buffer
_G.RunData = _G.RunData
	or {
		win = nil,
		buf = nil,
		system_obj = nil,
		term_channel = nil,
		output = {},
		gdb_process = nil,
	}

local function close_run_win()
	if _G.RunData.win ~= nil then
		vim.api.nvim_win_close(_G.RunData.win, false)
	end

	if _G.RunData.buf ~= nil then
		vim.api.nvim_buf_delete(_G.RunData.buf, { force = true })
	end

	_G.RunData.win = nil
	_G.RunData.buf = nil
end

local function cleanup_run_data(keep_output)
	keep_output = keep_output or false
	close_run_win()
	_G.RunData.system_obj = nil
	if not keep_output then
		_G.RunData.output = {}
	end
	_G.RunData.term_channel = nil
end

local function open_run_output()
	_G.RunData.buf = vim.api.nvim_create_buf(false, true)
	pcall(vim.api.nvim_buf_set_name, _G.RunData.buf, "Cargo Run Output")

	vim.keymap.set("n", "q", close_run_win, { buffer = _G.RunData.buf, nowait = true })
	vim.keymap.set("n", "<esc>", close_run_win, { buffer = _G.RunData.buf, nowait = true })

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
	_G.RunData.win = vim.api.nvim_open_win(_G.RunData.buf, true, config)
	_G.RunData.term_channel = vim.api.nvim_open_term(_G.RunData.buf, {})
	for _, line in ipairs(_G.RunData.output) do
		if line ~= "" then
			vim.api.nvim_chan_send(_G.RunData.term_channel, line .. "\n")
		end
	end

	local line_count = vim.api.nvim_buf_line_count(_G.RunData.buf)
	vim.api.nvim_win_set_cursor(_G.RunData.win, { line_count, 1 })
end

local function strip_ansi(str)
	return str:gsub("\27%[[%d;?]*[A-Za-z]", "")
end

local function on_run_output(_, data)
	if _G.RunData.system_obj == nil or data == nil or data == "" then
		return
	end

	local lines = vim.split(data, "\n", { plain = true, trimempty = true })
	for _, line in ipairs(lines) do
		if line:find("Error") then
			vim.notify(strip_ansi(line), vim.log.levels.ERROR)
		end

		_G.RunData.output[#_G.RunData.output + 1] = line
	end
end

--- @type fun(out: vim.SystemCompleted)
local function on_run_done(system_obj)
	local lines = vim.split(system_obj.stderr, "\n", { plain = true, trimempty = true })
	for _, line in ipairs(lines) do
		_G.RunData.output[#_G.RunData.output + 1] = line
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
	if _G.RunData.system_obj then
		vim.notify("Stopping running process...")
		_G.RunData.system_obj:kill(15)
		cleanup_run_data()
		return
	end

	vim.notify("Running frontend...")
	_G.RunData.system_obj = vim.system(
		{ "target/debug/frontend" },
		{ cwd = root_dir, stdout = on_run_output, text = true },
		on_run_done
	)

	-- Clean run output
	_G.RunData.output = {}
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

local function cargo_build(cont_func)
	vim.notify("Compiling...")
	vim.system({ "cargo", "build" }, { cwd = root_dir }, function(out)
		on_build_done(out)
		if out.code == 0 and cont_func ~= nil then
			cont_func()
		end
	end)
end

local function debug_test()
	local augrp = vim.api.nvim_create_augroup("FzfAutocmds", { clear = true })
	vim.api.nvim_create_autocmd("TermOpen", {
		callback = function()
			vim.cmd.startinsert()
		end,
		group = augrp,
	})

	local cur_line = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local pattern = "^%s*fn%s+([%a_][%w_]*)%s*%f[%s(]"
	local test_name = ""
	for i = cur_line[1], 1, -1 do
		local line = lines[i]
		test_name = string.match(line, pattern)
		if test_name ~= nil and test_name ~= "" then
			break
		end
	end

	if test_name == nil then
		vim.notify("Failed to find test name! Bailing!", vim.log.levels.ERROR)
		return
	end

	local buf = vim.fn.expand("%:p:h")

	vim.cmd.tabnew()
	local home = os.getenv("HOME")
	local app_name = os.getenv("NVIM_APPNAME") or "neovim"
	local script_path = home .. "/.config/" .. app_name .. "/scripts/debug_unit_test.sh"

	vim.cmd.term(script_path .. " " .. test_name .. " " .. buf)
	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })
end

local function debug_run()
	if _G.RunData.system_obj == nil or _G.RunData.system_obj.pid == nil then
		error("Failed to debug. Is the frontend running??")
		return
	end

	if _G.RunData.gdb_process ~= nil then
		if _G.RunData.gdb_process.job_id then
			pcall(vim.fn.jobstop, _G.RunData.gdb_process.job_id)
		elseif _G.RunData.gdb_process.pid then
			vim.system({ "kill", tostring(_G.RunData.gdb_process.pid) })
		end
		_G.RunData.gdb_process = nil
	end

	local cur_line = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_buf_get_name(0)

	vim.cmd.tabnew()

	local run_gdb = string.format(
		'rust-gdb -q target/debug/frontend -ex "set pagination off" -ex "set confirmation off" -ex "set breakpoint pending on" -ex "attach %i" -ex "b %s:%i" -ex "tui e", -ex "c"',
		_G.RunData.system_obj.pid,
		buf,
		cur_line[1]
	)

	vim.cmd.term(run_gdb)

	local job_id = vim.b.terminal_job_id
	local pid = vim.fn.jobpid(job_id)

	_G.RunData.gdb_process = {
		pid = pid,
		job_id = job_id,
		kill = function()
			vim.fn.jobstop(job_id)
		end,
	}
	vim.cmd.startinsert()
	vim.keymap.set("n", "<esc>", function()
		_G.RunData.gdb_process:kill()
		_G.RunData.gdb_process = nil
		vim.cmd("q")
	end, { buffer = 0 })
end

local function insert_generic()
	if vim.fn.pumvisible() ~= 0 then
		local key = vim.api.nvim_replace_termcodes("<ESC>i", true, false, true)
		vim.api.nvim_feedkeys(key, "n", true)
	end

	-- Needed so we wait for the PUM to close.
	vim.schedule(function()
		local line = vim.api.nvim_get_current_line()
		local new_line = line:gsub("(.*)%(", "%1::<>(")
		vim.api.nvim_set_current_line(new_line)
		local pos = new_line:match(".*()<")
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		vim.api.nvim_win_set_cursor(0, { cursor_pos[1], pos })
	end)
end

local function end_insert()
	local line = vim.api.nvim_get_current_line()
	local pos = line:match(".*()%)")
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_win_set_cursor(0, { cursor_pos[1], pos })
end

vim.keymap.set("n", "<leader>cc", cargo_build, { buffer = 0 })
vim.keymap.set("n", "<leader>cu", function()
	cargo_build(cargo_run)
end)
vim.keymap.set("n", "<leader>lr", open_run_output)
vim.keymap.set("n", "<leader>ct", cargo_test, { buffer = 0 })
vim.keymap.set("n", "<leader>dt", debug_test, { buffer = 0 })
vim.keymap.set("n", "<leader>du", function()
	cargo_build(function()
		if _G.RunData.system_obj == nil then
			cargo_run()
		end

		vim.schedule(debug_run)
	end)
end)
vim.keymap.set("i", "<C-g>", insert_generic, { buffer = 0 })
vim.keymap.set("i", "<C-e>", end_insert, { buffer = 0 })
