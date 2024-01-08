return {
  {
    'tanvirtin/vgit.nvim',
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require('vgit').setup()
    end
  },
  {
    'tveskag/nvim-blame-line',
    keys = {
      { '<leader>b', ':ToggleBlameLine<CR>', desc = "Toggle blame line" }
    }
  }
}
