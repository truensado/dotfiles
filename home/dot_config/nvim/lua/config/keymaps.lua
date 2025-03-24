-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local a = vim.api
a.nvim_create_user_command("Q", "q!", {})
a.nvim_create_user_command("W", "wq", {})
