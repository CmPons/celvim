local lsp_configs = require("lsp_configs")

local M = {}

local formatting = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_funcs = vim.api.nvim_create_augroup("LspFuncs", {})

-- Make sure the hover window can't be focused
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	focusable = false,
	border = "single",
})

local function setup_auto_complete()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = lsp_funcs,
		buffer = vim.api.nvim_get_current_buf(),
		nested = false,
		callback = function()
			if
				vim.fn.pumvisible() ~= 0
				or vim.fn.state("m") == "m"
				or vim.fn.state("a") == "a"
				or vim.snippet.active()
			then
				return
			end

			local char = vim.v.char
			if char == "(" or char == "," or char == "<" then
				local pos = vim.api.nvim_win_get_cursor(0)
				local row, col = pos[1], pos[2]

				-- Schedule is needed, probably because we are in textlock? idk
				-- If not, no window seems to show
				vim.schedule(function()
					local curr_line = vim.api.nvim_get_current_line()
					local orig_pos = { row, col + 1 }
					if char == "(" or char == "<" then
						col = col - 1
					elseif char == "," then
						local paren = curr_line:find("%(")
						if paren ~= nil then
							col = paren - 1
						else
							col = col - 1
						end
					end

					vim.api.nvim_win_set_cursor(0, { row, col })
					vim.lsp.buf.hover()
					vim.api.nvim_win_set_cursor(0, orig_pos)
				end)
			elseif char ~= ")" and char ~= ">" then
				local key = vim.keycode("<C-x><C-o>")
				vim.api.nvim_feedkeys(key, "m", false)
			end
		end,
	})
end

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

local function format_buf(formatter)
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)

	local result = vim.system({ formatter, filepath }):wait()
	if result.code ~= 0 then
		vim.notify("Failed to format: " .. result.stderr, vim.log.levels.ERROR)
		return
	end

	local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current = table.concat(current_lines, "\n")

	if current ~= result.stdout then
		local new_lines = vim.split(result.stdout, "\n", { trimempty = false })
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	end
end

local function register_format_on_save(autocmd_group)
	-- Format on save
	-- We MUST clear the autocmds before registering a new one! If not,
	-- we will overwrite any previous buffers!
	vim.api.nvim_clear_autocmds({ group = autocmd_group })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = formatting,
		callback = function()
			-- Specify buffer explicitly instead of 0, to avoid an assert.
			-- 0 works on previous version of neovim
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if clients[1] ~= nil then
				vim.lsp.buf.format({ 0 })
			elseif vim.bo.formatprg ~= "" then
				format_buf(vim.bo.formatprg)
			end
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
	for filetype, lsp in pairs(lsp_configs) do
		vim.api.nvim_create_autocmd({ "FileType" }, {
			group = lsp_funcs,
			pattern = filetype,
			callback = function()
				vim.wo.relativenumber = true
				vim.wo.number = true
				vim.notify("Starting " .. lsp.config.name)

				vim.lsp.start(lsp.config)

				setup_auto_complete()
				register_format_on_save(formatting)

				vim.lsp.set_log_level("debug")
			end,
		})

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			group = lsp_funcs,
			pattern = lsp.file_ext,
			callback = function()
				local clients = vim.lsp.get_clients({ name = lsp.config.name })
				if clients[1] ~= nil then
					vim.lsp.buf_attach_client(0, clients[1].id)
				else
					vim.lsp.start(lsp.config)
				end

				setup_auto_complete()
				register_format_on_save(formatting)
			end,
		})
	end
end

local function setup_signs()
	vim.fn.sign_define("DiagnosticSignError", {
		text = "", -- Error symbol
		texthl = "DiagnosticSignError",
		numhl = "DiagnosticSignError",
	})
	vim.fn.sign_define("DiagnosticSignWarn", {
		text = "", -- Warning symbol
		texthl = "DiagnosticSignWarn",
		numhl = "DiagnosticSignWarn",
	})

	vim.fn.sign_define("DiagnosticSignInfo", {
		text = "", -- Info symbol
		texthl = "DiagnosticSignInfo",
		numhl = "DiagnosticSignInfo",
	})

	vim.fn.sign_define("DiagnosticSignHint", {
		text = "󰌵", -- Hint symbol
		texthl = "DiagnosticSignHint",
		numhl = "DiagnosticSignHint",
	})
end

M.Init = function()
	setup_handlers()
	setup_signs()
	clear_lsp_log()
	setup_language_servers()
	vim.keymap.set("n", "<leader>ls", function()
		local log_file = vim.lsp.log.get_filename()
		vim.cmd.tabnew(log_file)
	end)
end

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = formatting })
	vim.api.nvim_clear_autocmds({ group = lsp_funcs })
end

return M
