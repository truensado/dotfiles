return {
  -- pairs
  { 
    'echasnovski/mini.pairs', 
    version = false,
    opts = {
      modes = { insert = true, command = false, terminal = false },
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
      },
    }
  },
  -- surround
  { 
    'echasnovski/mini.surround', 
    version = false,
    opts = {
      custom_surroundings = nil,
      highlight_duration = 500,
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`

        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },
      n_lines = 20,
      respect_selection_type = false,
      search_method = 'cover',
      silent = false,
    }
  },
  -- diff
  { 
    'echasnovski/mini.diff', 
    version = false,
    opts = {
      view = {
        style = vim.go.number and 'number' or 'sign',

        signs = { add = '▒', change = '▒', delete = '▒' },

        priority = 199,
      },

      source = nil,

      delay = {
        text_change = 200,
      },

      mappings = {
        apply = 'gh',

        reset = 'gH',

        textobject = 'gh',

        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
      },

      options = {
        algorithm = 'histogram',

        indent_heuristic = true,

        linematch = 60,

        wrap_goto = false,
      },
    }
  },
  -- icons
  { 
    'echasnovski/mini.icons', 
    version = false,
    opts = {
      style = 'glyph',
      default   = {},
      directory = {},
      extension = {},
      file      = {},
      filetype  = {},
      lsp       = {},
      os        = {},
      use_file_extension = function(ext, file) return true end,
    }
  },
  -- statusline
  { 
    'echasnovski/mini.statusline', 
    version = false,
    opts = {
      content = {
        active = nil,
        inactive = nil,
      },
      use_icons = true,
      set_vim_settings = true,
    }
  },
  -- notify
  { 
    'echasnovski/mini.notify', 
    version = false,
    opts = {
      -- Content management
      content = {
        -- Function which formats the notification message
        -- By default prepends message with notification time
        format = nil,

        -- Function which orders notification array from most to least important
        -- By default orders first by level and then by update timestamp
        sort = nil,
      },
      -- Notifications about LSP progress
      lsp_progress = {
        -- Whether to enable showing
        enable = true,

        -- Notification level
        level = 'INFO',

        -- Duration (in ms) of how long last message should be shown
        duration_last = 1000,
      },

      -- Window options
      window = {
        -- Floating window config
        config = {},

        -- Maximum window width as share (between 0 and 1) of available columns
        max_width_share = 0.382,

        -- Value of 'winblend' option
        winblend = 25,
      },
    },
    { 
      'echasnovski/mini.indentscope', 
      version = false,
      opts = {
        -- Draw options
        draw = {
          delay = 100,
          predicate = function(scope) return not scope.body.is_incomplete end,
          priority = 2,
        },

        mappings = {
          object_scope = 'ii',
          object_scope_with_border = 'ai',
          goto_top = '[i',
          goto_bottom = ']i',
        },

        options = {
          border = 'both',
          indent_at_cursor = true,
          n_lines = 10000,
          try_as_border = false,
        },
        symbol = '╎',
      }
    }
  }
}
