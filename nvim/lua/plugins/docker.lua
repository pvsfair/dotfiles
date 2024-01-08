return {
  {
    "dgrbrady/nvim-docker",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "pvsfair/reactivex.nvim",
    },
    keys = {
      { "<leader>lc", function() require('nvim-docker').containers.list_containers() end }
    }
  }
}
