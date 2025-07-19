local snippet_funcs = vim.api.nvim_create_augroup("SnippetFuncs", {})
local snippets = require("lsp.snippet_defs")

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

local function curr_word()
	local line = vim.api.nvim_get_current_line()
	local pos = vim.api.nvim_win_get_cursor(0)
	local col = pos[2]

	if line == nil or line == "" then
		return ""
	end
	local break_chars = { " ", ".", "(", ")", "<", ">", "," }

	local start = 1
	local i = col
	while i >= 1 do
		local curr_char = line:sub(i, i)
		local hit_break_char = false
		for _, break_char in ipairs(break_chars) do
			if curr_char == break_char then
				hit_break_char = true
				break
			end
		end

		if hit_break_char then
			-- Currently ON a break_char so add one
			start = i + 1
			break
		end
		i = i - 1
	end

	return line:sub(start, col)
end

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
		local curr_line = vim.api.nvim_get_current_line()
		local new_line = curr_line:sub(1, #curr_line - #completed_item.abbr)
		vim.api.nvim_set_current_line(new_line)

		local snippet_text = completed_item.user_data.nvim.lsp.completion_item.insertText

		vim.snippet.expand(snippet_text)
		vim.api.nvim_del_autocmd(complete_done)
		complete_done = nil
	elseif completed_item.kind == "Keyword" then
		vim.api.nvim_set_current_line("")
		local snippet_text = completed_item.user_data.nvim.lsp.completion_item.textEdit.newText
		vim.snippet.expand(snippet_text)
		vim.api.nvim_del_autocmd(complete_done)
		complete_done = nil
	end
end

vim.api.nvim_create_autocmd("CompleteChanged", {
	group = snippet_funcs,
	callback = function()
		local filetype_snippets = snippets[vim.bo.filetype]
		local word = curr_word()
		if filetype_snippets ~= nil and word ~= "" then
			for _, snip in ipairs(filetype_snippets) do
				if string.find(snip.word, word) ~= nil then
					vim.fn.complete_add(snip)
				end
			end
		end

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
