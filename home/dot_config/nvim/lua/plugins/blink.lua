return {
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = "*",
    opts = {
      keymap = { 
        preset = 'default',
        ['<Tab>'] = { 'select_next', 'fallback' },
      },

      appearance = {
        nerd_font_variant = 'mono'
      },

      completion = { documentation = { auto_show = false } },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = "prefer_rust" }
    },
    opts_extend = { "sources.default" }
  }
}
