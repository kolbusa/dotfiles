-- TODO: https://github.com/glepnir/lspsaga.nvim

local on_attach = function(client, bufnr)
    -- Initialize compiletion-nvim
    if vim.g.cmp_enabled == 0 then
        require('completion').on_attach()
    end

    require('lsp_signature').on_attach({
      hint_enable = false,
      hint_prefix = '>',
      -- floating_window = false,
      -- always_trigger = true,
      max_height = 20,
      max_width = 160,
      doc_lines = 40,
      floating_window_above_cur_line = true,
      hi_parameter = 'LspReferenceRead',
      select_signature_key = '<C-n>',
      -- hi_parameter = 'LspSignatureActiveParameter',
    })

    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings.
    local opts = {noremap=true, silent=true}

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<Leader>gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', '<Leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<Leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<Leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<Leader>gR', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<Leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<Leader>gf', '<cmd>lua vim.lsp.buf.format({timeout_ms = 10000})<CR>', opts)
    buf_set_keymap('v', '<Leader>gf', '<cmd>lua vim.lsp.buf.format({timeout_ms = 10000})<CR>', opts)
    -- buf_set_keymap('v', '<Leader>gf', '<cmd>lua vim.lsp.buf.formatexpr()<CR>', opts)

    buf_set_keymap('n', '<C-J>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('i', '<C-J>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<C-K>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('i', '<C-K>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

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

-- do nothing in diff mode
-- XXX: not sure how this works when diff mode enabled later
if vim.api.nvim_get_option_value("diff", {}) then
    return
end

local lspconfig = require('lspconfig')
local capabilities = nil

if vim.g.cmp_enabled then
    capabilities = require('cmp_nvim_lsp').default_capabilities()
end

function getenv_with_default(envname, default)
    local result = os.getenv(envname)
    if result == nil then
        result = default
    end
    return result
end

-- TODO: wrap this into a function
local clangd_path = getenv_with_default('CLANGD_PATH', 'clangd')
if vim.fn.executable(clangd_path) == 1 then
    vim.lsp.enable('clangd')
    vim.lsp.config('clangd', {
        -- cmd = {clangd_path, '--background-index', '--pch-storage=memory', '--j=8', '--enable-config'},
        cmd = {clangd_path, '--background-index', '--j=2', '--clang-tidy', '--header-insertion=iwyu', '--completion-style=detailed', '--function-arg-placeholders', '--fallback-style=llvm', '--pch-storage=memory', '--enable-config'},
        filetypes = {'c', 'cpp', 'objc', 'objcpp', 'cuda'},
        on_attach = on_attach,
        capabilities = capabilities,
    })
end

-- local pylsp_path = getenv_with_default('PYLSP_PATH', 'pylsp')
-- local cmd = {pylsp_path}
-- if os.getenv('PYLSP_DEBUG') == '1' then
--     cmd = {pylsp_path, '--log-file', '/Users/rdubtsov/work/playground/lsp/pylsp.log', '-v', '-v', '-v', '-v' }
-- end
-- lspconfig.pylsp.setup{
--     cmd = cmd,
--     filetypes = {'python'},
--     on_attach = on_attach,
--     capabilities = capabilities,
-- }

local basedpyright_path = getenv_with_default('BASEDPYRIGHT_PATH', 'basedpyright-langserver')
if vim.fn.executable(basedpyright_path) == 1 then
    vim.lsp.enable('basedpyright')
    vim.lsp.config('basedbyright', {
        cmd = {basedpyright_path, '--stdio'},
        on_attach = on_attach,
        capabilities = capabilities,
    })
end

local sourcekit_path = getenv_with_default('SOURCEKIT_PATH', 'sourcekit-lsp')
if vim.fn.executable(sourcekit_path) == 1 then
    vim.lsp.enable('sourcekit')
    vim.lsp.config('sourcekit', {
        cmd = {sourcekit_path},
        filetypes = {'swift'},
        on_attach = on_attach,
        capabilities = capabilities,
    })
end

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

