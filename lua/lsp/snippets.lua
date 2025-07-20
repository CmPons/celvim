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
	local completion_item = vim.tbl_get(completed_item, "user_data", "nvim", "lsp", "completion_item")

	if completion_item == nil then
		return
	end

	local insertFormat = completion_item.insertTextFormat or 0

	-- 2 == Is a snippet from the LSP
	-- This is for Rust mainly. A lot of the text edits that aren't labeled as snippets still are'
	if insertFormat == 2 and completion_item.textEdit ~= nil then
		local textEdit = completion_item.textEdit
		local snippet_text = nil

		-- We don't use apply_text_edits here since it doesn't handle snippets
		if textEdit ~= nil then
			if textEdit.range ~= nil then
				-- To prepare for the snippet, erase the placeholder completion item
				local startChar = textEdit.range.start.character
				local curr_line = vim.api.nvim_get_current_line()
				local split_line = string.sub(curr_line, 1, startChar)
				vim.api.nvim_set_current_line(split_line)
			else
				-- Best effort based upon the assumption the abbr is inserted
				local curr_line = vim.api.nvim_get_current_line()
				local new_line = curr_line:sub(1, #curr_line - #completed_item.abbr)
				vim.api.nvim_set_current_line(new_line)
			end

			snippet_text = completion_item.textEdit.newText
			vim.snippet.expand(snippet_text)
		end

		-- Apply these edits after in case they are deletions
		local buf_nr = vim.api.nvim_get_current_buf()
		local additional_edits = completion_item.additionalTextEdits
		if additional_edits ~= nil then
			vim.lsp.util.apply_text_edits(additional_edits, buf_nr, "utf-8")
		end
	-- This section mainly handles lua
	elseif completed_item.kind == "Snippet" and insertFormat == 2 and completion_item.insertText ~= nil then
		local curr_line = vim.api.nvim_get_current_line()
		local new_line = curr_line:sub(1, #curr_line - #completed_item.abbr)
		vim.api.nvim_set_current_line(new_line)
		vim.snippet.expand(completion_item.insertText)
	end

	vim.api.nvim_del_autocmd(complete_done)
	complete_done = nil
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
