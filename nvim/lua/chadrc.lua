-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

local stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

M.ui = {
  lazyVim = true,
  theme = "catppuccin",
  transparency = true,
  nvdash = {
    load_on_startup = true,
    buttons = {
      { "  Find File", "Spc f f", "Telescope find_files" },
      { "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
      { "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
      { "  Bookmarks", "Spc m a", "Telescope marks" },
      { "  Themes", "Spc t h", "Telescope themes" },
      { "  Mappings", "Spc c h", "NvCheatsheet" },
      {
        "  Restore Session",
        "Spc s s",
        "RestoreSession",
      },
    },
  },
  statusline = {
    theme = "default",
    order = {
      "mode",
      "relativepath",
      "file",
      "git",
      "%=",
      "lsp_msg",
      "%=",
      "formatStatus",
      "diagnostics",
      "lsp",
      "cwd",
      "cursor",
    },
    modules = {
      -- testthing = function ()
      --   return require('auto-session.lib').current_session_name
      -- end
      formatStatus = function()
        return "Format "
          .. (vim.g.disable_autoformat and "OFF|" or "ON|")
          .. (vim.b.disable_autoformat and "OFF" or "ON")
        -- return require('auto-session.lib').current_session_name
      end,
      relativepath = function()
        local path = vim.api.nvim_buf_get_name(stbufnr())

        if path == "" then
          return ""
        end

        return "%#St_relativepath#  " .. vim.fn.expand "%:.:h" .. "/"
      end,
    },
  },
  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

return M
