-- TODO: https://github.com/glepnir/lspsaga.nvim

local on_attach = function(client, bufnr)
    -- Initialize compiletion-nvim
    if vim.g.cmp_enabled == 0 then
        require('completion').on_attach()
    end
    require('lsp_signature').on_attach({hint_prefix='>', hi_parameter='IncSearch'})

    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings.
    local opts = {noremap=true, silent=true}

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<Leader>gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', '<Leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    -- buf_set_keymap('n', '<Leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<Leader>gR', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<Leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<Leader>gf', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
    buf_set_keymap('v', '<Leader>gf', '<cmd>lua vim.lsp.buf.formatexpr()<CR>', opts)

    buf_set_keymap('n', '<C-K>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    -- buf_set_keymap('n', '<Leader>gq', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

    local signs = { Error = "▶︎", Warn = "▷", Hint = "●", Info = "○" }
    for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = false,
    })

    if client.server_capabilities.documentHighlightProvider then
        vim.o.updatetime = 500
        vim.api.nvim_create_autocmd("CursorHold", {
            buffer = bufnr,
            callback = function()
                local opts = {
                    focusable = false,
                    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                    border = 'rounded',
                    source = 'always',
                    prefix = ' ',
                    scope = 'cursor',
                }
                vim.diagnostic.open_float(nil, opts)
                vim.lsp.buf.document_highlight();
            end
        })
        vim.api.nvim_create_autocmd("CursorHoldI", {
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.document_highlight();
            end
        })
        vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.clear_references();
            end
        })
        vim.api.nvim_create_autocmd("CursorMovedI", {
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.clear_references();
            end
        })
    end
end


local lspconfig = require('lspconfig')
local capabilities = nil

if vim.g.cmp_enabled then
    capabilities = require('cmp_nvim_lsp').default_capabilities()
end

-- TODO: wrap this into a function
local clangd_path = os.getenv('CLANGD_PATH')
if clangd_path == nil then
    clangd_path = 'clangd'
end
lspconfig.clangd.setup{
    cmd = {clangd_path, '--background-index', '--pch-storage=disk', '--j=1'},
    filetypes = {'c', 'cpp', 'objc', 'objcpp', 'cuda'},
    on_attach = on_attach,
    capabilities = capabilities,
}

local pylsp_path = os.getenv('PYLSP_PATH')
if pylsp_path == nil then
    pylsp_path = 'pylsp'
end
local cmd = {pylsp_path}
if os.getenv('PYLSP_DEBUG') == '1' then
    cmd = {pylsp_path, '--log-file', '/Users/rdubtsov/work/playground/lsp/pylsp.log', '-v', '-v', '-v', '-v' }
end
lspconfig.pylsp.setup{
    cmd = cmd,
    filetypes = {'python'},
    on_attach = on_attach,
    capabilities = capabilities,
}

-- Keep a list of all errors (both location list and quickfix list)
do
  local method = 'textDocument/publishDiagnostics'
  local default_handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, method, result, client_id, bufnr, config)
    default_handler(err, method, result, client_id, bufnr, config)
    vim.diagnostic.setloclist({
        open = false,
    })
  end
end

