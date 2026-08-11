-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Open the completion popup menu on the first Tab press
vim.opt.wildmode = "full"

-- Neovide-only: font zoom with Ctrl+= / Ctrl+- / Ctrl+0, persisted across restarts
if vim.g.neovide then
  local scale_file = vim.fn.stdpath("data") .. "/neovide_scale.txt"

  -- Restore last zoom level
  local f = io.open(scale_file, "r")
  if f then
    local saved = tonumber(f:read("*a"))
    f:close()
    vim.g.neovide_scale_factor = saved or 1.0
  end

  local function set_scale(value)
    vim.g.neovide_scale_factor = value
    local out = io.open(scale_file, "w")
    if out then
      out:write(tostring(value))
      out:close()
    end
  end

  vim.keymap.set({ "n", "v", "i" }, "<C-=>", function()
    set_scale(vim.g.neovide_scale_factor * 1.1)
  end, { desc = "Neovide zoom in" })
  vim.keymap.set({ "n", "v", "i" }, "<C-->", function()
    set_scale(vim.g.neovide_scale_factor / 1.1)
  end, { desc = "Neovide zoom out" })
  vim.keymap.set({ "n", "v", "i" }, "<C-0>", function()
    set_scale(1.0)
  end, { desc = "Neovide zoom reset" })
end
