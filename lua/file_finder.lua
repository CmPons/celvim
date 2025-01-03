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
                vim.cmd.tabnew(file)

                local utils = require("utils")

                local filetype = utils.get_filetype(file)
                if filetype ~= nil then
                    vim.bo.filetype = filetype
                    vim.bo.syntax = utils.get_syntax_from_filetype(filetype)
                end
            end
        end,
        group = augrp,
    })

    vim.cmd.tabnew()

    vim.cmd.term("fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'")
    vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })
end

vim.keymap.set("n", "<leader>ff", fuzzy_find, { desc = "Find File" })
vim.keymap.set("n", "<space><space>", fuzzy_find, { desc = "Find File" })
