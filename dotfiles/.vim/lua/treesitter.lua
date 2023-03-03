require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = false,
    disable = function(lang, bufnr)
      if vim.api.nvim_buf_line_count(bufnr) >= 10000 then
        return false
      else
        if vim.g.ufo_enabled == 0 then
          vim.bo.foldmethod = "expr"
          vim.bo.foldexpr = "nvim_treesitter#foldexpr()"
        end
        return true
      end
    end
  },
  rainbow = {
    enable = true,
    extended_mode = false, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = 10000, -- Do not enable for files with more than n lines, int
  },
}

