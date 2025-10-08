local a = vim.api

a.nvim_create_user_command("Q", "q!", {})
a.nvim_create_user_command("W", "wq", {})
a.nvim_create_user_command(
  "Replace",
  function(opts)
    local f = opts.fargs
    if #f < 2 then
      print("Usage: :Replace <from> <to>")
      return
    end
    local from = vim.fn.escape(f[1], '/\\')
    local to   = vim.fn.escape(f[2], '/\\')
    vim.cmd(string.format("%%s/%s/%s/g", from, to))
  end,
  {
    nargs = "+",
    desc = "Global replace in buffer"
  }
)
