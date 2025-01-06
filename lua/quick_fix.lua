local M = {}
M.preview_buf = nil
M.preview_win = nil
M.qf_win = nil

local quick_fix_funcs = vim.api.nvim_create_augroup("QuickFixFuncs", {})

local close_qf = function()
  vim.api.nvim_win_close(M.qf_win, false)
  vim.api.nvim_win_close(M.preview_win, false)

  M.qf_win = nil
  M.preview_buf = nil
  M.preview_win = nil
end

local function create_preview_win()
  if M.preview_buf == nil and M.preview_win == nil then
    M.preview_buf = vim.api.nvim_create_buf(false, true)
    local prev_config = {
      relative = "editor",
      row = 3,
      col = 10,
      width = 125,
      height = 20,
      border = "single",
      style = "minimal",
    }
    M.preview_win = vim.api.nvim_open_win(M.preview_buf, false, prev_config)
  end
end

local function setup_preview_win()
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    buffer = vim.api.nvim_get_current_buf(),
    group = quick_fix_funcs,
    callback = function()
      local line = vim.split(vim.api.nvim_get_current_line(), "|")
      local file = line[1]
      local lines = {}
      for file_line in io.lines(file) do
        lines[#lines + 1] = file_line
      end

      if M.preview_buf ~= nil then
        vim.api.nvim_buf_set_lines(M.preview_buf, 0, -1, false, lines)

        local utils = require("utils")
        local file_type = utils.get_filetype(file)
        if file_type ~= nil then
          vim.bo[M.preview_buf].filetype = file_type
          vim.bo[M.preview_buf].syntax = utils.get_syntax_from_filetype(file_type)
        end

        local cursor = vim.split(line[2], " ")
        local row, col = tonumber(cursor[1]), tonumber(cursor[3])
        vim.api.nvim_win_set_cursor(M.preview_win, { row, col })
        vim.api.nvim_buf_add_highlight(M.preview_buf, -1, "BufferVisible", row - 1, 0, -1)
      end
    end,
  })
end

local function on_select_qf_line(line)
  close_qf()

  local split_line = vim.split(line, "|")
  local cursor = vim.split(split_line[2], " ")
  local row, col = tonumber(cursor[1]), tonumber(cursor[3])
  local file = split_line[1]

  vim.cmd.tabnew(file)
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { row, col })
end

local function setup_qf_keymaps()
  vim.keymap.set("n", "<esc>", function()
    close_qf()
  end, { buffer = vim.api.nvim_get_current_buf() })

  vim.keymap.set("n", "q", function()
    close_qf()
  end, { buffer = vim.api.nvim_get_current_buf() })

  vim.keymap.set("n", "<enter>", function()
    local line = vim.api.nvim_get_current_line()
    on_select_qf_line(line)
  end, { buffer = vim.api.nvim_get_current_buf() })
end

local function change_qf_to_float()
  M.qf_win = vim.api.nvim_get_current_win()
  local config = {
    relative = "editor",
    row = 25,
    col = 10,
    width = 125,
    height = 5,
    border = "single",
    style = "minimal",
  }
  vim.api.nvim_win_set_config(0, config)
end

local function on_enter_quick_fix()
  vim.cmd(":hi QuickFixLine NONE")
  vim.cmd(":hi qfLineNr NONE")

  setup_qf_keymaps()
  change_qf_to_float()
  create_preview_win()
  setup_preview_win()
end

local function setup_quick_fix()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    nested = true,
    group = quick_fix_funcs,
    callback = function()
      if vim.fn.win_gettype() == "quickfix" then
        on_enter_quick_fix()
      end
    end,
  })
end

M.Init = function()
  setup_quick_fix()
end

M.Cleanup = function()
  vim.api.nvim_clear_autocmds({ group = quick_fix_funcs })
end

return M
