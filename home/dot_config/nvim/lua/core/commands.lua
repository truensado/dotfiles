local map = vim.api

map.nvim_create_user_command("Q", "q!", {})
map.nvim_create_user_command("W", "wq", {})
