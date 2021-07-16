-- TODO: https://github.com/glepnir/lspsaga.nvim

local on_attach = function(client, bufnr)
    -- Initialize compiletion-nvim
    require'completion'.on_attach()

    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings.
    local opts = { noremap=true, silent=true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<Leader>gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', '<Leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    -- buf_set_keymap('n', '<Leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<Leader>gR', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<Leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<Leader>gf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    -- buf_set_keymap('n', '<Leader>gq', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
end

-- TODO: wrap this into a function
local clangd_path = os.getenv('CLANGD_PATH')
if clangd_path == nil then
    clangd_path = 'clangd'
end
require('lspconfig').clangd.setup{
    cmd = {clangd_path, '--background-index', '--pch-storage=disk', '--j=1'},
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    on_attach = on_attach
}

local pylsp_path = os.getenv('PYLSP_PATH')
if pylsp_path == nil then
    pylsp_path = 'pylsp'
end
require('lspconfig').pylsp.setup{
    cmd = {pylsp_path},
    filetypes = { 'python' },
    on_attach = on_attach
}

-- Keep a list of all errors (both location list and quickfix list)
do
  local method = 'textDocument/publishDiagnostics'
  local default_handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, method, result, client_id, bufnr, config)
    default_handler(err, method, result, client_id, bufnr, config)
    vim.lsp.diagnostic.set_loclist({
        open_loclist = false,
    })
    local diagnostics = vim.lsp.diagnostic.get_all()
    local qflist = {}
    for bufnr, diagnostic in pairs(diagnostics) do
      for _, d in ipairs(diagnostic) do
        d.bufnr = bufnr
        d.lnum = d.range.start.line + 1
        d.col = d.range.start.character + 1
        d.text = d.message
        table.insert(qflist, d)
      end
    end
    vim.lsp.util.set_qflist(qflist)
  end
end

-- Highlighting
vim.o.updatetime = 100
vim.api.nvim_exec([[
    highlight default link LspDiagnosticsDefaultError Error
    highlight default link LspReferenceText myReference
    highlight default link LspReferenceRead myReference
    highlight default link LspReferenceWrite myReference
    augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
    augroup END
]], false)

