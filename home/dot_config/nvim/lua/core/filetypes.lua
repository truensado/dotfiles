vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.tmpl",
  callback = function()
    local filename = vim.fn.expand("%:t") -- get the filename
    local match = filename:match(".*%.([^.]+)%.tmpl$")
    if match then
      vim.bo.filetype = match
    end
  end,
})
