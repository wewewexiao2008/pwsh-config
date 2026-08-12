return {
  -- Sidekick: drive Claude Code (and other agent CLIs) from inside Neovim
  { import = "lazyvim.plugins.extras.ai.sidekick" },

  -- Minuet: AI-powered tab completion (ghost text), Cursor-style.
  -- Uses DeepSeek V4 (FIM) via the openai_fim_compatible provider.
  -- API key is read from the DEEPSEEK_API_KEY env var.
  { import = "lazyvim.plugins.extras.ai.minuet" },
  {
    "milanglacier/minuet-ai.nvim",
    opts = {
      provider = "openai_fim_compatible",
      provider_options = {
        openai_fim_compatible = {
          api_key = "DEEPSEEK_API_KEY",
          name = "deepseek",
          end_point = "https://api.deepseek.com/beta/completions",
          model = "deepseek-chat",
          optional = {
            max_tokens = 256,
            top_p = 0.9,
          },
        },
      },
      -- Enable ghost-text completion automatically on all filetypes.
      virtualtext = {
        auto_trigger_ft = { "*" },
        keymap = {
          accept = "<A-A>", -- accept whole suggestion
          accept_line = "<A-a>", -- accept one line
          next = "<A-]>", -- cycle next suggestion
          prev = "<A-[>", -- cycle previous suggestion
          dismiss = "<A-e>", -- dismiss suggestion
        },
      },
    },
  },
}
