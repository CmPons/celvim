local M = {}
M.preview_buf = nil
M.preview_win = nil
M.qf_win = nil
M.search_buf = nil
M.search_win = nil
M.original_qf_items = nil

local function create_search_win()
	if M.search_buf == nil and M.search_win == nil then
		M.search_buf = vim.api.nvim_create_buf(false, true)
		local search_config = {
			relative = "editor",
			row = 30,
			col = 10,
			width = 125,
			height = 1,
			border = "single",
			style = "minimal",
		}

		vim.bo[M.search_buf].buftype = "prompt"
		vim.fn.prompt_setprompt(M.search_buf, "Filter:")

		M.search_win = vim.api.nvim_open_win(M.search_buf, true, search_config)

		M.original_qf_items = vim.fn.getqflist()

		vim.api.nvim_create_autocmd("TextChangedI", {
			buffer = M.search_buf,
			callback = function()
				local query = vim.api.nvim_buf_get_lines(M.search_buf, 0, -1, false)[1]

				if query == "" then
					vim.fn.setqflist(M.original_qf_items)
				else
					query = query:gsub("Filter:", "")
					print("Query", query)
					local filtered_items = {}
					for _, item in ipairs(M.original_qf_items) do
						if item.text:lower():find(query:lower()) then
							table.insert(filtered_items, item)
						end
					end
					vim.fn.setqflist(filtered_items)
				end
				vim.fn.setqflist({}, "a", { idx = 1 })
				setup_preview_win()
			end,
		})

		vim.keymap.set("i", "<C-n>", function()
			local qf_info = vim.fn.getqflist({ size = true, idx = 0 })
			local new_idx = math.min(qf_info.idx + 1, qf_info.size)
			vim.fn.setqflist({}, "a", { idx = new_idx })
			setup_preview_win()
		end, { buffer = M.search_buf })

		vim.keymap.set("i", "<C-p>", function()
			local qf_info = vim.fn.getqflist({ idx = 0 })
			local new_idx = math.max(qf_info.idx - 1, 1)
			vim.fn.setqflist({}, "a", { idx = new_idx })
			setup_preview_win()
		end, { buffer = M.search_buf })

		vim.keymap.set("i", "<enter>", function()
			vim.api.nvim_set_current_win(M.qf_win)
			local line = vim.api.nvim_get_current_line()
			on_select_qf_line(line)
		end, { buffer = M.search_buf })

		vim.cmd("startinsert!")
	end
end

local quick_fix_funcs = vim.api.nvim_create_augroup("QuickFixFuncs", {})

local close_qf = function()
	if M.qf_win and vim.api.nvim_win_is_valid(M.qf_win) then
		vim.api.nvim_win_close(M.qf_win, false)
	end
	if M.preview_win and vim.api.nvim_win_is_valid(M.preview_win) then
		vim.api.nvim_win_close(M.preview_win, false)
	end

	if M.search_win and vim.api.nvim_win_is_valid(M.search_win) then
		vim.api.nvim_win_close(M.search_win, false)
	end

	M.qf_win = nil
	M.preview_buf = nil
	M.preview_win = nil
	M.search_buf = nil
	M.search_win = nil
	M.original_qf_items = nil
end

local function create_preview_win()
	if M.preview_buf == nil and M.preview_win == nil then
		M.preview_buf = vim.api.nvim_create_buf(false, true)
		local prev_config = {
			relative = "editor",
			row = 1,
			col = 10,
			width = 125,
			height = 20,
			border = "single",
			style = "minimal",
		}
		M.preview_win = vim.api.nvim_open_win(M.preview_buf, false, prev_config)
	end
end

local qf_list_highlight = vim.api.nvim_create_namespace("qf_list_hi")

function setup_preview_win()
	vim.api.nvim_set_current_win(M.qf_win)
	local line = vim.split(vim.api.nvim_get_current_line(), "|", { trimempty = true })
	local file = line[1]
	if #line < 3 or vim.fn.isdirectory(file) == 1 then
		warn("Failed to setup preview for file", file)
		return
	end

	local lines = {}
	for file_line in io.lines(file) do
		lines[#lines + 1] = file_line
	end

	if M.preview_buf ~= nil then
		vim.api.nvim_buf_set_lines(M.preview_buf, 0, -1, false, lines)

		local utils = require("utils")
		local file_type = utils.get_filetype(file)
		if file_type ~= nil then
			vim.bo[M.preview_buf].filetype = file_type
			vim.bo[M.preview_buf].syntax = utils.get_syntax_from_filetype(file_type)
		end

		local cursor = vim.split(line[2], " ")
		local row, col = tonumber(cursor[1]), tonumber(cursor[3])
		vim.api.nvim_win_set_cursor(M.preview_win, { row, col })
		vim.api.nvim_buf_add_highlight(M.preview_buf, -1, "BufferVisible", row - 1, 0, -1)

		local current = vim.fn.getqflist({ idx = 0 }).idx
		local qf_buf = vim.api.nvim_win_get_buf(M.qf_win)
		vim.api.nvim_buf_clear_namespace(qf_buf, qf_list_highlight, 0, -1)
		vim.api.nvim_buf_add_highlight(qf_buf, qf_list_highlight, "BufferVisible", current - 1, 0, -1)
	end
	vim.api.nvim_set_current_win(M.search_win)
end

function on_select_qf_line(line)
	close_qf()

	local split_line = vim.split(line, "|")
	local cursor = vim.split(split_line[2], " ")
	local row, col = tonumber(cursor[1]), tonumber(cursor[3])
	local file = split_line[1]

	vim.cmd.tabnew(file)
	vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { row, col })
	vim.cmd.stopinsert()
end

local function setup_qf_keymaps()
	vim.keymap.set("n", "<esc>", function()
		vim.cmd.stopinsert()
		close_qf()
	end, { buffer = vim.api.nvim_get_current_buf() })

	vim.keymap.set("n", "q", function()
		vim.cmd.stopinsert()
		close_qf()
	end, { buffer = vim.api.nvim_get_current_buf(), nowait = true })
end

local function change_qf_to_float()
	M.qf_win = vim.api.nvim_get_current_win()
	local config = {
		relative = "editor",
		row = 23,
		col = 10,
		width = 125,
		height = 5,
		border = "single",
		style = "minimal",
	}
	vim.api.nvim_win_set_config(0, config)
end

local function on_enter_quick_fix()
	vim.cmd(":hi QuickFixLine NONE")
	vim.cmd(":hi qfLineNr NONE")

	change_qf_to_float()
	create_preview_win()
	create_search_win()
	setup_qf_keymaps()
	setup_preview_win()
end

local function setup_quick_fix()
	vim.api.nvim_create_autocmd("BufWinEnter", {
		nested = true,
		group = quick_fix_funcs,
		callback = function()
			if vim.fn.win_gettype() == "quickfix" then
				on_enter_quick_fix()
			end
		end,
	})
end

M.Init = function()
	setup_quick_fix()
end

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = quick_fix_funcs })
end

return M
