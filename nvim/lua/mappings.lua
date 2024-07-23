require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local del = vim.keymap.del

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })
map("n", "n", "nzzzv", { desc = "Find next" })
map("n", "N", "Nzzzv", { desc = "Find previous" })

map("n", "<leader>fe", "<cmd>FormatEnable<CR>", { desc = "autoformat-on-save Enable" })
map("n", "<leader>fdd", "<cmd>FormatDisable<CR>", { desc = "autoformat-on-save Disable" })
map("n", "<leader>fdb", "<cmd>FormatDisable!<CR>", { desc = "autoformat-on-save Disable for buffer" })
del("t", "<esc>")
-- vim functions
local api = vim.api

api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "autoformat-on-save Re-enable",
})
