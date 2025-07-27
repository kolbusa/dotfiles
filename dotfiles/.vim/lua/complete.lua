-- NOTE: this file is strategically named to not conflict with cmp.lua from nvim-cmp and completion.lua from
-- lsp-completion.

-- Set up nvim-cmp.
local cmp = require'cmp'

local execute_if_visible = function(callback, options)
    if cmp.visible() then
        callback(options)
    end
end


cmp.setup({
    experimental = {
        ghost_text = false,
    },
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = {
        ['<C-b>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                return cmp.scroll_docs(-4)
            end
            fallback()
        end}),
        ['<C-f>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                return cmp.scroll_docs(4)
            end
            fallback()
        end}),
        ['<Down>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                return cmp.select_next_item()
            end
            fallback()
        end}),
        ['<Up>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                return cmp.select_prev_item()
            end
            fallback()
        end}),
        ['<Tab>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                local self = cmp.complete_common_string()
                if cmp.visible() then
                    self = cmp.select_next_item()
                end
                return self
            end
            fallback()
        end}),
        ['<CR>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                if cmp.get_active_entry() then
                    return cmp.confirm({select = false})
                end
            end
            fallback()
        end}),
        ['<C-e>'] = cmp.mapping({i = function(fallback)
            if cmp.visible() then
                return cmp.abort()
            end
            fallback()
        end}),
    },
    sources = cmp.config.sources(
      -- { { name = 'nvim_lsp_signature_help' }, },
      { { name = 'nvim_lsp' }, },
      { { name = 'path' }, },
      -- { { name = 'cmdline' }, },
      { { name = 'buffer' }, }
    ),
  }
)
