function FuzzyFind()
	local output_buf = vim.api.nvim_create_buf(false, true)
	local config = {
		relative = "editor",
		row = 0,
		col = 25,
		width = 100,
		height = 25,
		border = "double",
		style = "minimal",
		title = "fzf",
	}
	local fzf_output = vim.api.nvim_open_win(output_buf, false, config)

	local input_buf = vim.api.nvim_create_buf(false, true)
	local input_config = {
		relative = "editor",
		row = 27,
		col = 25,
		width = 100,
		height = 1,
		border = "double",
		style = "minimal",
	}
	local input = vim.api.nvim_open_win(input_buf, true, input_config)
	vim.cmd.startinsert()

	vim.keymap.set("n", "<escape>", function()
		vim.api.nvim_win_close(fzf_output, true)
		vim.api.nvim_win_close(input, true)
	end, { buffer = input_buf })

	Setupfzf(output_buf, input)
end

vim.keymap.set("n", "<leader>ff", FuzzyFind, { desc = "Find File" })

function Setupfzf(output_buf, input_buf)
	local output = vim.system({ "fzf" }, { text = true }):wait()

	vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { output.stdout })
end
