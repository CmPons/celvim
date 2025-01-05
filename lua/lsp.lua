local M = {}
M.preview_buf = nil
M.preview_win = nil
M.qf_win = nil

local formatting = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_funcs = vim.api.nvim_create_augroup("LspFuncs", {})

local function clear_lsp_log()
	local home = os.getenv("HOME")
	local path = home .. "/.local/state/celvim/lsp.log"
	os.remove(path)
	local file = io.open(path, "w")
	if file ~= nil then
		file:write("")
		file:close()
	end
end

local function register_format_on_save(autocmd_group, bufnr)
	-- Format on save
	-- We MUST clear the autocmds before registering a new one! If not,
	-- we will overwrite any previous buffers!
	vim.api.nvim_clear_autocmds({ group = autocmd_group })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = formatting,
		callback = function()
			-- Specify buffer explicitly instead of 0, to avoid an assert.
			-- 0 works on previous version of neovim
			vim.lsp.buf.format({ bufnr })
		end,
	})
end

local function setup_handlers()
	vim.api.nvim_create_autocmd("LspProgress", {
		callback = function(ev)
			local params = ev.data.params
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if params.value.kind == "report" and client ~= nil then
				vim.notify(client.name .. " -- " .. params.value.title)
			end
		end,
	})
end

local function setup_language_servers()
	-- lua-language-server setup
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = lsp_funcs,
		pattern = { "*.lua" },
		callback = function(ev)
			vim.wo.relativenumber = true
			vim.wo.number = true

			vim.lsp.start({
				name = "lua-lsp-server",
				cmd = { "lua-language-server" },
				root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),

				-- Note Lua must be capital. This setting is to remove complaints about unknown global "vim"
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						runtime = {
							version = "LuaJIT",
						},
						workspace = {
							-- This lets the lsp know where the Neovim lua runtime files are
							-- and enables auto-complete with the Neovim api.
							library = vim.api.nvim_get_runtime_file("", true),
						},
					},
				},
			})
			vim.lsp.set_log_level("INFO")

			register_format_on_save(formatting, ev.buf)
		end,
	})

	-- Rust language server setup
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = { "rs" },
		callback = function(ev)
			-- Hack to disable other rust lsp, probably due to my nixos setup
			local clients = vim.lsp.get_clients({ name = "rust-analyzer" })
			if clients[1] ~= nil then
				vim.lsp.stop_client(clients[1], true)
			end

			clients = vim.lsp.get_clients({ name = "rust-lsp" })
			if clients[1] ~= nil then
				return
			end

			vim.wo.relativenumber = true
			vim.wo.number = true
			vim.notify("Starting rust-analyzer")

			vim.lsp.start({
				name = "rust-lsp",
				cmd = { "rust-analyzer" },
				root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]),
			})
			vim.lsp.set_log_level("INFO")

			register_format_on_save(formatting, ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "TabNew", "TabEnter", "BufEnter", "BufWinEnter" }, {
		pattern = { "*.rs" },
		callback = function(ev)
			-- Hack to disable other rust lsp, probably due to my nixos setup
			local clients = vim.lsp.get_clients({ name = "rust-analyzer" })
			if clients[1] ~= nil then
				vim.lsp.stop_client(clients[1], true)
			end

			clients = vim.lsp.get_clients({ name = "rust-lsp" })
			if clients[1] ~= nil then
				print("Attaching to " .. tostring(ev.buf) .. " because of " .. ev.event)
				vim.lsp.buf_attach_client(0, clients[1].id)
				register_format_on_save(formatting, ev.buf)
			end
		end,
	})
end

local function setup_quick_fix()
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = lsp_funcs,
		callback = function()
			local win_type = vim.fn.win_gettype()

			if win_type == "quickfix" then
				vim.cmd(":hi QuickFixLine NONE")
				vim.cmd(":hi qfLineNr NONE")
				vim.keymap.set("n", "q", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })

				M.qf_win = vim.api.nvim_get_current_win()
				local config = {
					relative = "editor",
					row = 25,
					col = 10,
					width = 125,
					height = 5,
					border = "single",
					style = "minimal",
				}
				vim.api.nvim_win_set_config(0, config)

				vim.api.nvim_create_autocmd({ "CursorMoved" }, {
					buffer = vim.api.nvim_get_current_buf(),
					group = lsp_funcs,
					callback = function()
						if M.preview_buf == nil and M.preview_win == nil then
							M.preview_buf = vim.api.nvim_create_buf(false, true)
							local prev_config = {
								relative = "editor",
								row = 3,
								col = 10,
								width = 125,
								height = 20,
								border = "single",
								style = "minimal",
							}
							M.preview_win = vim.api.nvim_open_win(M.preview_buf, false, prev_config)
						end

						local line = vim.split(vim.api.nvim_get_current_line(), "|")
						local file = line[1]
						local lines = {}
						for file_line in io.lines(file) do
							lines[#lines + 1] = file_line
						end
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
					end,
				})
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufLeave" }, {
		group = lsp_funcs,
		callback = function()
			if vim.api.nvim_get_current_win() == M.qf_win then
				vim.schedule(function()
					if M.qf_win ~= nil then
						pcall(vim.api.nvim_win_close, M.qf_win, false)
					end

					if M.preview_win ~= nil then
						pcall(vim.api.nvim_win_close, M.preview_win, false)
					end

					M.qf_win = nil
					M.preview_win = nil
					M.preview_buf = nil
				end)
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = lsp_funcs,
		callback = function()
			if vim.api.nvim_get_current_win() == M.qf_win then
				vim.schedule(function()
					if M.preview_win ~= nil then
						pcall(vim.api.nvim_win_close, M.preview_win, false)
					end

					M.qf_win = nil
					M.preview_win = nil
					M.preview_buf = nil
				end)
			end
		end,
	})
end

local function setup_auto_complete()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = lsp_funcs,
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			if vim.fn.pumvisible() == 1 or vim.fn.state("m") == "m" then
				return
			end
			local char = vim.v.char
			local key = vim.keycode("<C-x><C-o>")
			vim.api.nvim_feedkeys(key, "m", false)
		end,
	})
end

M.Init = function()
	setup_handlers()
	clear_lsp_log()
	setup_language_servers()
	setup_quick_fix()
	setup_auto_complete()
end

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = formatting })
	vim.api.nvim_clear_autocmds({ group = lsp_funcs })
end

return M
