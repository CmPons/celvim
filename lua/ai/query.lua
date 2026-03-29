local M = {}

M.query_buf = nil
M.query_win = nil
M.prompt = "User: "
M.bot = "Bot: "
M.snippet_length = 25
M.system_prompt = [[
<SystemPrompt>
  You are a programming assistant embedded in Neovim. The user is asking a question while editing code.                                                                                                              
  Context:                                                                                                                                                                                                           
  - File: Current file the user has open      
  - Cursor: Line their cursor is at
  - Snippet: A few lines before and after the cursor pos

  Use this context as a clue to infer what the user is working on, but only reference it if relevant to their question. Be concise and direct. If the question is about code, prefer short explanations with code
  snippets. Do not repeat the question back.
  </SystemPrompt>
]]

--- @type fun(out: vim.SystemCompleted)
M.query_finish = function(out)
	if out == nil then
		return
	end

	local stdout = M.bot .. out.stdout
	local lines = vim.split(stdout, "\n")
	vim.api.nvim_buf_set_lines(M.query_buf, -1, -1, false, lines)
	vim.api.nvim_buf_set_lines(M.query_buf, -1, -1, false, { "User: " })

	local lines = vim.api.nvim_buf_get_lines(M.query_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(M.query_win, { #lines, #M.prompt })
end

M.open_query_window = function()
	local last_buff = vim.api.nvim_buf_get_name(0)
	local last_win = vim.api.nvim_get_current_win()
	local cursor_pos = vim.api.nvim_win_get_cursor(last_win)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local from = math.max(1, cursor_pos[1] - M.snippet_length)
	local to = math.min(#lines, cursor_pos[1] + M.snippet_length)
	local last_snippet_lines = vim.api.nvim_buf_get_lines(0, from, to, false)
	local last_snippet = table.concat(last_snippet_lines, "\n") .. "\n"

	vim.cmd("tabnew")
	M.query_buf = vim.api.nvim_get_current_buf()
	M.query_win = vim.api.nvim_get_current_win()

	vim.api.nvim_buf_set_lines(M.query_buf, 0, 0, false, { "User: " })
	vim.api.nvim_win_set_cursor(M.query_win, { 1, #M.prompt })
	vim.cmd("startinsert")

	local auto_mode = "--dangerously-skip-permissions"
	if vim.fn.has("win32") == 1 then
		auto_mode = "--enable-auto-mode"
	end

	vim.keymap.set("i", "<enter>", function()
		local lines = vim.api.nvim_buf_get_lines(M.query_buf, 0, -1, false)
		local prompt = table.concat(lines, "\n") .. "\n"

		prompt = string.format(
			[[
    %s
    <Context>
    File=%s
    Line=%d
    Snippet=\n%s
    </Context>

    <Conversation>
    %s
    </Conversation>
    ]],
			M.system_prompt,
			last_buff,
			cursor_pos[1],
			last_snippet,
			prompt
		)

		info("Query prompt", prompt)

		vim.system({ "claude", "--model", "haiku", auto_mode, "-p", prompt }, vim.schedule_wrap(M.query_finish))
	end, { desc = "AI Query", buffer = M.query_buf })
end

M.Init = function()
	vim.keymap.set("n", "<leader>ai", function()
		M.open_query_window()
	end, { desc = "AI Reviewer" })
end

M.Shutdown = function() end

return M
