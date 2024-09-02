return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function ()
    local treesitter = require("nvim-treesitter.configs")

    treesitter.setup({
      higlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
      autotag = {
        enalbe = true,
      },
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "toml",
        "html",
        "css",
        "markdown",
        "markdown_inline",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "dart",
        "erlang",
        "elixir",
        "kotlin",
        "java",
        "swift",
      },
    })
  end,
}
