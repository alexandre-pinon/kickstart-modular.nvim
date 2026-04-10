return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'

      -- Install parsers
      local parsers = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'typescript',
        'tsx',
      }
      ts.install(parsers)

      -- Enable highlighting for these languages
      vim.api.nvim_create_autocmd('FileType', {
        pattern = parsers,
        callback = function(args)
          vim.treesitter.start(args.buf)

          -- Optional: Enable indentation
          -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Optional: Enable folding
          -- vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          -- vim.wo[0][0].foldmethod = 'expr'
        end,
      })

      -- Disable folding by default (optional)
      vim.api.nvim_command 'set nofoldenable'
    end,
  },
}
