-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.clipboard = ""
vim.opt.mouse = ""

vim.opt.list = false
vim.opt.listchars = {
  tab = "→ ",
  space = "·",
  eol = "↲",
  trail = "•",
}

local function trim_trailing_whitespace()
  local save = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(save)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = trim_trailing_whitespace,
})

-- vim.g.snacks_animate_scroll = false
-- to disable all animations
vim.g.snacks_animate = false
