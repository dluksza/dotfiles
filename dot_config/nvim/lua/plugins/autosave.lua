return {
  "pocco81/auto-save.nvim",
  enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  trigger_events = { "InsertLeave", "TextChanged" },
  opts = {
    deounce_delay = 250,
    wite_all_buffers = true,
  },
}
