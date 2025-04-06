return {
  "akinsho/flutter-tools.nvim",
  ft = "dart",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    fvm = true,
    decorations = {
      app_version = true,
      device = true,
    },
    debugger = { enabled = true },
    dev_log = { notify_errors = true },
  },
  config = function(_, opts)
    require("flutter-tools").setup(opts)
    require("telescope").load_extension("flutter")
  end,
}
