local M = {}

local session_cmds = vim.api.nvim_create_augroup("session_cmds", { clear = true })

local get_session_filename = function()
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local filename, _ = cwd:gsub("/", "_")
  filename, _ = filename:gsub(":", "_")
  filename, _ = filename:gsub("%.", "_")
  return filename
end

local get_session_folder = function()
  local home_path = os.getenv("HOME")
  if home_path == nil then
    return nil
  end

  vim.opt.sessionoptions:append("localoptions")

  return vim.fs.normalize(home_path .. "/.local/state/celvim/sessions/")
end

local get_session_file_fullpath = function()
  if get_session_folder() == nil then
    return nil
  end

  return get_session_folder() .. "/" .. get_session_filename() .. ".vim"
end

M.Init = function()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = session_cmds,
    callback = function()
      local session_folder = get_session_folder()
      if session_folder == nil then
        return
      end

      vim.opt.sessionoptions:append("localoptions")

      vim.fn.mkdir(session_folder, "p")

      vim.cmd("mksession! " .. get_session_file_fullpath() .. ".vim")
    end,
  })

  vim.api.nvim_create_user_command("LoadSession", function()
    local session_file_fullpath = get_session_file_fullpath()
    if session_file_fullpath == nil or vim.uv.fs_stat(session_file_fullpath) == nil then
      error("Failed to load session file")
      return
    end

    session_file_fullpath = vim.fs.normalize(session_file_fullpath)
    vim.notify("Loading session from " .. session_file_fullpath)

    -- Delete all buffers first
    vim.cmd("%bd!")

    vim.cmd.source(session_file_fullpath)
  end, {})
end

M.Cleanup = function()
  vim.api.nvim_clear_autocmds({ group = session_cmds })
end

return M
