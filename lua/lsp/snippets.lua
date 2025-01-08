local snippet_funcs = vim.api.nvim_create_augroup("SnippetFuncs", {})

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

local complete_done = nil
local function on_complete_done()
	local completed_item = vim.v.completed_item

	if completed_item.kind == "Snippet" then
		local row = vim.api.nvim_win_get_cursor(0)[1] - 1
		vim.api.nvim_buf_set_lines(0, row, row + 1, false, {})

		local snippet_text = completed_item.user_data.nvim.lsp.completion_item.insertText

		local snippet_lines = vim.split(snippet_text, "\n")
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		-- This seems to stop us from overwriting any other lines
		table.insert(lines, row + 1, "")

		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

		vim.snippet.expand(snippet_text)
		vim.api.nvim_del_autocmd(complete_done)
		complete_done = nil
	end
end

vim.api.nvim_create_autocmd("CompleteChanged", {
	group = snippet_funcs,
	callback = function()
		if complete_done == nil then
			complete_done = vim.api.nvim_create_autocmd({ "CompleteDone" }, {
				group = snippet_funcs,
				callback = function()
					on_complete_done()
				end,
			})
		end
	end,
})
