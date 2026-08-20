ts_forge = require("ts-forge")
ts_forge.setup({
    -- Parsers to ensure are installed.
    -- Bundled parsers (c, lua, markdown, etc.) are included automatically.
    ensure_installed = {},

    -- Automatically install missing parsers on startup (async).
    auto_install = false,

    -- Where to store compiled parsers, queries, and revision info.
    -- Default location is already on Neovim's runtimepath.
    install_dir = vim.fn.stdpath("data") .. "/site",
})

ts_forge.parsers.cuda = {
    url = "https://github.com/tree-sitter-grammars/tree-sitter-cuda",
    rev = "48b066f334f4cf2174e05a50218ce2ed98b6fd01",
}
