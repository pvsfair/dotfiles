vim.g.mapleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.updatetime = 50

-- Move lines With hjkl
vim.cmd("nnoremap <A-j> :m .+1<CR>==")
vim.cmd("nnoremap <A-k> :m .-2<CR>==")
vim.cmd("inoremap <A-j> <Esc>:m .+1<CR>==gi")
vim.cmd("inoremap <A-k> <Esc>:m .-2<CR>==gi")
vim.cmd("vnoremap <A-j> :m '>+1<CR>gv=gv")
vim.cmd("vnoremap <A-k> :m '<-2<CR>gv=gv")
-- vim.cmd('inoremap <silent><expr> <TAB> pumvisible() ? "\\<C-n>" : "\\<TAB>"')
-- vim.cmd('inoremap <expr><S-TAB> pumvisible() ? "\\<C-p>" : "\\<C-h>"')

-- vim.keymap.set('i', '<Tab>', function() print(require('cmp').visible()) end, {expr=true})
-- vim.keymap.set('i', "<Tab>", function() return require('cmp').visible() and '<C-n>' or '<Tab>' end, {silent = true, expr = true})
-- vim.keymap.set('i', "<S-Tab>", function() return require('cmp').visible() and '<C-p>' or '<C-h>' end, {expr = true})
vim.keymap.set('i', "jk", "<ESC>")
vim.keymap.set('i', "<CapsLock>", "<ESC>")

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Find next" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Find previous" })

vim.keymap.set("n", "<leader>y", "\"+y", { desc = "Copy to machine clipboard" })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = "Copy to machine clipboard" })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "Copy to machine clipboard" })
