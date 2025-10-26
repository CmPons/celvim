local lsp_configs = require("lsp_configs")

local M = {}

local function setup_auto_complete()
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = M.lsp_funcs,
    nested = false,
    callback = function()
      local char = vim.v.char
      if char == "(" or char == "," or char == "<" then
        local pos = vim.api.nvim_win_get_cursor(0)
        local row, col = pos[1], pos[2]

        -- Schedule is needed, probably because we are in textlock? idk
        -- If not, no window seems to show
        vim.schedule(function()
          local curr_line = vim.api.nvim_get_current_line()
          local orig_pos = { row, col + 1 }
          if char == "(" or char == "<" then
            col = col - 1
          elseif char == "," then
            local paren = curr_line:find("%(")
            if paren ~= nil then
              col = paren - 1
            else
              col = col - 1
            end
          end

          vim.api.nvim_win_set_cursor(0, { row, col })
          vim.lsp.buf.hover()
          vim.api.nvim_win_set_cursor(0, orig_pos)
        end)
      elseif char ~= ")" and char ~= ">" then
        vim.schedule(function()
          vim.lsp.omnifunc(1, 0)
        end)
      end
    end,
  })
end

local function clear_lsp_log()
  local home = os.getenv("HOME")
  local path = home .. "/.local/state/celvim/lsp.log"
  os.remove(path)
  local file = io.open(path, "w")
  if file ~= nil then
    file:write("")
    file:close()
  end
end

M.format_buf = function(formatter)
  local result = vim.system({ formatter, vim.api.nvim_buf_get_name(0) }):wait()
  if result.code ~= 0 then
    vim.notify("Failed to format: " .. result.stderr, vim.log.levels.ERROR)
    return
  end
end

local function register_format_on_save(autocmd_group)
  -- Format on save
  -- We MUST clear the autocmds before registering a new one! If not,
  -- we will overwrite any previous buffers!
  vim.api.nvim_clear_autocmds({ group = autocmd_group })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = M.formatting,
    callback = function()
      -- Specify buffer explicitly instead of 0, to avoid an assert.
      -- 0 works on previous version of neovim
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if clients[1] ~= nil then
        vim.lsp.buf.format({ 0 })
      elseif vim.bo.formatprg ~= "" then
        M.format_buf(vim.bo.formatprg)
      end
    end,
  })
end

local function setup_handlers()
  vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(ev)
      local params = ev.data.params
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if params.value.kind == "report" and client ~= nil then
        vim.notify(client.name .. " -- " .. params.value.title)
      end
    end,
  })
end

local function setup_language_servers()
  setup_auto_complete()

  for filetype, lsp in pairs(lsp_configs) do
    vim.api.nvim_create_autocmd({ "FileType" }, {
      group = M.lsp_funcs,
      pattern = filetype,
      callback = function()
        vim.wo.relativenumber = true
        vim.wo.number = true
        vim.notify("Starting " .. lsp.config.name)

        vim.lsp.start(lsp.config)

        register_format_on_save(M.formatting)

        vim.lsp.set_log_level("INFO")
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = M.lsp_funcs,
      pattern = lsp.file_ext,
      callback = function()
        local clients = vim.lsp.get_clients({ name = lsp.config.name })
        if clients[1] ~= nil then
          vim.lsp.buf_attach_client(0, clients[1].id)
        else
          vim.lsp.start(lsp.config)
        end

        register_format_on_save(M.formatting)
      end,
    })
  end
end

local function setup_signs()
  vim.fn.sign_define("DiagnosticSignError", {
    text = "", -- Error symbol
    texthl = "DiagnosticSignError",
    numhl = "DiagnosticSignError",
  })
  vim.fn.sign_define("DiagnosticSignWarn", {
    text = "", -- Warning symbol
    texthl = "DiagnosticSignWarn",
    numhl = "DiagnosticSignWarn",
  })

  vim.fn.sign_define("DiagnosticSignInfo", {
    text = "", -- Info symbol
    texthl = "DiagnosticSignInfo",
    numhl = "DiagnosticSignInfo",
  })

  vim.fn.sign_define("DiagnosticSignHint", {
    text = "󰌵", -- Hint symbol
    texthl = "DiagnosticSignHint",
    numhl = "DiagnosticSignHint",
  })
end

M.Init = function()
  M.formatting = vim.api.nvim_create_augroup("LspFormatting", {})
  M.lsp_funcs = vim.api.nvim_create_augroup("LspFuncs", {})

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    focusable = false,
    border = "single",
  })

  setup_handlers()
  setup_signs()
  clear_lsp_log()
  setup_language_servers()

  vim.keymap.set("n", "<leader>ls", function()
    local log_file = vim.lsp.log.get_filename()
    vim.cmd.tabnew(log_file)
  end)
end

M.Cleanup = function()
  vim.api.nvim_clear_autocmds({ group = M.formatting })
  vim.api.nvim_clear_autocmds({ group = M.lsp_funcs })
end

return M
