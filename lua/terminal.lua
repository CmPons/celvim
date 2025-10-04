vim.keymap.set("n", "<C-/>", function()
	vim.cmd.Terminal()
end, {})

vim.keymap.set("n", "<CS-/>", function()
	local current_dir = vim.fn.getcwd()
	vim.cmd.Terminal(current_dir .. "/engine")
end, {})

vim.keymap.set("n", "<CA-/>", function()
	local current_dir = vim.fn.expand("%:p:h")
	local results = vim.fs.find({ "Cargo.toml", ".git" }, { upward = true, path = current_dir })
	if #results > 0 then
		vim.cmd.Terminal(vim.fs.dirname(results[1]))
	else
		vim.cmd.Terminal()
	end
end, {})

vim.cmd([[tnoremap <Esc> <C-\><C-n>]])

vim.api.nvim_create_user_command("Terminal", function(opts)
	local dir = ""
	if #opts.fargs > 0 then
		dir = opts.fargs[1]
	end

	vim.cmd("tabnew")

	if dir ~= "" then
		-- Doing this the more complicated way so "zsh" is still the tabname
		vim.cmd.term("zsh -c 'cd " .. dir .. "; zsh -i'")
	else
		vim.cmd.term("zsh")
	end

	vim.cmd("startinsert")
	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })
end, { nargs = "?" })
