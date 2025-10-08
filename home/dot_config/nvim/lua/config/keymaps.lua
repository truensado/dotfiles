local k = vim.keymap.set

k('n', '<Tab>', ':tabnext<CR>', { silent = true })
k('n', '<S-Tab>', ':tabprevious<CR>', { silent = true })
k('n', '<A-h>', '<C-w>h', { silent = true })
k('n', '<A-j>', '<C-w>j', { silent = true })
k('n', '<A-k>', '<C-w>k', { silent = true })
k('n', '<A-l>', '<C-w>l', { silent = true })
k('n', 'ss', ':vsplit<Return>', { silent = true })
k('n', 'sh', ':split<Return>', { silent = true })
k('n', '<leader>r', ':Replace ', { desc = 'Start Replace command' })
k('n', '<leader>q', ':q<CR>', { desc = 'quit' })
k('n', '<leader>w', ':w<CR>', { desc = 'quick save' })
