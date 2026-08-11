return {
  -- Yazi file manager inside Neovim (reuses the user's yazi config)
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      { "<leader>-", "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
      { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open yazi in nvim's working directory" },
    },
    opts = {
      -- keep directory args handled by the explorer autocmd
      open_for_directories = false,
    },
  },
}
