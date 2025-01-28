vim.lsp.inlay_hint.enable(true)

local root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]) or "."

-- {"type":"suite","event":"ok","passed":5,"failed":0,"ignored":5,"measured":0,"filtered_out":82,"exec_time":0.151350578}

--- @type fun(out: vim.SystemCompleted)
---
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
vim.keymap.set("n", "<leader>tt", cargo_test, { buffer = 0 })
