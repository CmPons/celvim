local function get_filetype(file_name)
	local dot_pos = string.find(file_name, "%.")
	if dot_pos == nil then
		return nil
	end
	local ext = string.sub(file_name, dot_pos + 1, -1)
	return ext
end

local function fuzzy_find()
	local augrp = vim.api.nvim_create_augroup("FzfAutocmds", { clear = true })

	vim.api.nvim_create_autocmd("TermOpen", {
		callback = function()
			vim.cmd.startinsert()
		end,
		group = augrp,
	})

	vim.api.nvim_create_autocmd("TermClose", {
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local file = nil
			if #lines > 0 then
				file = lines[1]
			end

			if file ~= nil then
				vim.api.nvim_clear_autocmds({ group = augrp })
				vim.api.nvim_buf_delete(0, { force = true })
				vim.cmd.tabedit(file)

				local filetype = get_filetype(file)
				if filetype ~= nil then
					vim.cmd("set filetype=" .. filetype)
				end
			end
		end,
		group = augrp,
	})

	vim.cmd.term("fzf")
end

vim.keymap.set("n", "<leader>ff", fuzzy_find, { desc = "Find File" })
vim.keymap.set("n", "<space><space>", fuzzy_find, { desc = "Find File" })
