#!/usr/bin/env bash

local function workspace_search()
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

			if file == nil then
				return
			end

			local stdout = vim.split(file, ":")

			if #stdout < 2 then
				return
			end

			local file_name = stdout[1]
			local line = tonumber(stdout[2])

			vim.api.nvim_clear_autocmds({ group = augrp })
			vim.api.nvim_buf_delete(0, { force = true })
			vim.cmd.tabnew(file_name)
			vim.api.nvim_win_set_cursor(0, { line, 0 })

			local utils = require("utils")

			local filetype = utils.get_filetype(file_name)
			if filetype ~= nil then
				vim.bo.filetype = filetype
				vim.bo.syntax = utils.get_syntax_from_filetype(filetype)
			end
		end,
		group = augrp,
	})

	vim.cmd.tabnew()
	vim.cmd.term("./scripts/search.sh")
	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })
end

vim.keymap.set("n", "<space>/", workspace_search, { desc = "Grep (dir)" })
