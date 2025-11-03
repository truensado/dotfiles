local map = vim.keymap.set
local opts = {  noremap = true, silent = true }

-- cycle tabs
map("n", "<Tab>", ":tabnext<CR>", opts)
map("n", "<S-Tab>", ":tabprevious<CR>", opts)

-- navigate windows
map("n", "<A-Left>", "<C-w>h", opts)
map("n", "<A-Down>", "<C-w>j", opts)
map("n", "<A-Up>", "<C-w>k", opts)
map("n", "<A-Right>", "<C-w>l", opts)

map("n", "ss", ":vsplit<Return>", opts)
map("n", "sh", ":split<Return>", opts)

-- quick paste in directions
map("n", "<leader><S-Down>", "p", opts)
map("n", "<leader><S-Up>", "P", opts)

-- quick paste in directions
map("n", "<leader>g", ":%y<CR>", opts)

-- Indent left / right
map("v", "<leader><Left>", "<gv", opts)
map("v", "<leader><Right>", ">gv", opts)
map("n", "<leader><Left>", "<<", opts)
map("n", "<leader><Right>", ">>", opts)

-- move line up / down
map("n", "<leader><Up>", ":m .-2<CR>==", opts)
map("n", "<leader><Down>", ":m .+1<CR>==", opts)

-- Select block
map("n", "<leader>v", "<C-v>", opts)
map("n", "vv", "V", opts)

-- Delete without copying
map("n", "d", "\"_d", opts)
map("v", "d", "\"_d", opts)

-- Clear search highlight: leader + c
map("n", "<leader>c", ":nohlsearch<CR>", opts)

-- Replace current word globally: leader + s
map("n", "<leader>r", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]])

-- quick save/quit
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>w", function() vim.cmd("w") vim.notify("File Saved") end, opts)
