return {
  {
    {
      'akinsho/toggleterm.nvim',
      version = "*",
      config = function()
        require("toggleterm").setup({
          -- direction = "float",
        })
      end,
      keys = {
        { '<leader>cm', function() require("toggleterm").toggle() end, desc = "Toggle terminal" },
        { '<esc>', [[<C-\><C-n>]], mode = 't', desc = "Escape terminal" },
      }
    }
    -- {'akinsho/toggleterm.nvim', version = "*", opts = {--[[ things you want to change go here]]}}
  }
}
