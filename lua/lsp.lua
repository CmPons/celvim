local M = {}

local formatting = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_funcs = vim.api.nvim_create_augroup("LspFuncs", {})

M.Init = function()
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

	-- lua-language-server setup
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = lsp_funcs,
		pattern = { "*.lua" },
		callback = function(ev)
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

			register_format_on_save(formatting, ev.buf)
		end,
	})

	-- Rust language server setup
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.rs" },
		callback = function(ev)
			vim.lsp.start({
				name = "rust-lsp",
				cmd = { "rust-analyzer" },
				root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]),
			})

			register_format_on_save(formatting, ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = lsp_funcs,
		callback = function(ev)
			local win_type = vim.fn.win_gettype()

			if win_type == "quickfix" then
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
				local height = #lines
				if height > 10 then
					height = 10
				end

				local config = {
					relative = "editor",
					row = 25,
					col = 25,
					width = 100,
					height = #lines,
					border = "single",
					style = "minimal",
				}
				vim.api.nvim_win_set_config(0, config)
			end
		end,
	})

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

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = formatting })
	vim.api.nvim_clear_autocmds({ group = lsp_funcs })
end

return M
