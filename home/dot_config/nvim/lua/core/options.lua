local map = vim.opt

map.number = true

map.title = true

map.autoindent = true
map.smartindent = true

map.hlsearch = true

map.expandtab = true
map.tabstop = 2
map.softtabstop = 2
map.shiftwidth = 2
map.smarttab = true

map.scrolloff = 10

map.shell = "fish"

map.backupskip = { "/tmp/*", "/private/tmp/*" }

map.inccommand = "split"

map.ignorecase = true
map.smartcase = true

map.wrap = false

map.backspace = { "start", "eol", "indent" }

map.path:append({ "**" })

map.encoding = "utf-8"
map.fileencoding = "utf-8"

map.wildignore:append({ "*/node_modules/*" })

map.splitbelow = true 
map.splitright = true 

map.splitkeep = "cursor"
map.mouse = ""

map.clipboard = "unnamedplus"

map.termguicolors = true
