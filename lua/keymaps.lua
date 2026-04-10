-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Close current buffer
vim.keymap.set('n', '<leader>Q', ':bd<CR>', { desc = 'Close current buffer' })

-- Rename current file (with LSP import updates if available)
vim.keymap.set('n', '<leader>Fr', function()
  local old_name = vim.api.nvim_buf_get_name(0)
  local old_name_tail = vim.fn.fnamemodify(old_name, ':t')

  vim.ui.input({
    prompt = 'Rename file: ',
    default = old_name_tail,
  }, function(new_name_tail)
    if not new_name_tail or new_name_tail == '' or new_name_tail == old_name_tail then
      return
    end

    local dir = vim.fn.fnamemodify(old_name, ':h')
    local new_name = dir .. '/' .. new_name_tail

    -- Rename file on disk first
    local ok = vim.uv.fs_rename(old_name, new_name)
    if not ok then
      vim.notify('Failed to rename file on disk', vim.log.levels.ERROR)
      return
    end

    -- Update LSP workspace if supported (Neovim 0.11+ syntax)
    local clients = vim.lsp.get_clients { bufnr = 0 }
    for _, client in ipairs(clients) do
      if client:supports_method 'workspace/willRenameFiles' then
        local params = {
          files = {
            {
              oldUri = vim.uri_from_fname(old_name),
              newUri = vim.uri_from_fname(new_name),
            },
          },
        }
        local resp = client:request_sync('workspace/willRenameFiles', params, 1000, 0)
        if resp and resp.result then
          vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
        end
      end
    end

    -- Update buffer
    vim.cmd.saveas(new_name)
    vim.fn.delete(old_name)

    vim.notify('Renamed: ' .. old_name_tail .. ' -> ' .. new_name_tail, vim.log.levels.INFO)
  end)
end, { desc = '[F]ile [R]ename' })

vim.keymap.set('n', '<leader>cF', function() vim.fn.setreg('+', vim.fn.expand '%:p') end, { desc = 'Copy absolute path' })
vim.keymap.set('n', '<leader>bo', ':%bd|e#|bd#<CR>|normal `"<CR>', { desc = 'Close all other buffers' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank { timeout = 200 } end,
})

-- Restore cursor position on file open
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position on file open',
  group = vim.api.nvim_create_augroup('kickstart-restore-cursor', { clear = true }),
  pattern = '*',
  callback = function()
    local line = vim.fn.line '\'"'
    if line > 1 and line <= vim.fn.line '$' then
      vim.cmd 'normal! g\'"'
    end
  end,
})

-- auto-create missing dirs when saving a file
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Auto-create missing dirs when saving a file',
  group = vim.api.nvim_create_augroup('kickstart-auto-create-dir', { clear = true }),
  pattern = '*',
  callback = function()
    local dir = vim.fn.expand '<afile>:p:h'
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
