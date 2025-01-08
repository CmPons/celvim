local lsp_configs = require("lsp_configs")

local M = {}

local formatting = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_funcs = vim.api.nvim_create_augroup("LspFuncs", {})

vim.keymap.set("i", "<CR>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-y>"
	else
		return "<CR>"
	end
end, { expr = true })

vim.keymap.set({ "i", "s" }, "<Tab>", function()
	if vim.snippet.active({ direction = 1 }) then
		return "<cmd>lua vim.snippet.jump(1)<CR>"
	else
		return "<Tab>"
	end
end, { expr = true })

local orig_complete = vim.fn.complete
vim.fn.complete = function(findstart, items)
	if type(items) == "table" then
		for _, item in ipairs(items) do
			if item.kind == "Snippet" then
				item.word = item.abbr
			end
		end
	end
	return orig_complete(findstart, items)
end

vim.api.nvim_create_autocmd("CompleteDone", {
	group = lsp_funcs,
	callback = function()
		local completed_item = vim.v.completed_item
		print(vim.inspect(completed_item))

		if completed_item.kind == "Snippet" then
			local row = vim.api.nvim_win_get_cursor(0)[1] - 1
			vim.api.nvim_buf_set_lines(0, row, row + 1, false, {})

			local snippet_text = completed_item.user_data.nvim.lsp.completion_item.insertText
			vim.snippet.expand(snippet_text)
		end
	end,
})

local function setup_auto_complete()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = lsp_funcs,
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			if
				vim.fn.pumvisible() == 1
				or vim.fn.state("m") == "m"
				or vim.fn.state("a") == "a"
				or vim.snippet.active()
			then
				return
			end

			local key = vim.keycode("<C-x><C-o>")
			vim.api.nvim_feedkeys(key, "m", false)
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
	for filetype, lsp in pairs(lsp_configs) do
		vim.api.nvim_create_autocmd({ "FileType" }, {
			group = lsp_funcs,
			pattern = filetype,
			callback = function(ev)
				vim.wo.relativenumber = true
				vim.wo.number = true
				vim.notify("Starting " .. lsp.config.name)

				vim.lsp.start(lsp.config)

				setup_auto_complete()
				register_format_on_save(formatting, ev.buf)

				vim.lsp.set_log_level("INFO")
			end,
		})

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			group = lsp_funcs,
			pattern = { lsp.file_ext },
			callback = function(ev)
				local clients = vim.lsp.get_clients({ name = lsp.config.name })
				if clients[1] ~= nil then
					vim.lsp.buf_attach_client(0, clients[1].id)
					setup_auto_complete()
					register_format_on_save(formatting, ev.buf)
				end
			end,
		})
	end
end

M.Init = function()
	setup_handlers()
	clear_lsp_log()
	setup_language_servers()
end

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = formatting })
	vim.api.nvim_clear_autocmds({ group = lsp_funcs })
end

return M
