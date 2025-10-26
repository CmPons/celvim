-- File: tests/minimal_init.lua

-- 1. Add the current directory (your plugin's root) to the runtimepath.
-- This is the Lua equivalent of 'set rtp+=.'
vim.opt.rtp:prepend(vim.fn.getcwd())

-- 2. Manually source the plenary plugin definition file.
-- This is the crucial step that fixes the race condition. It ensures
-- the PlenaryBustedDirectory command is properly defined *before* the
-- -c flag from your Makefile tries to run it.
-- This is the Lua equivalent of 'runtime plugin/plenary.vim'
vim.cmd('runtime plugin/plenary.vim')
