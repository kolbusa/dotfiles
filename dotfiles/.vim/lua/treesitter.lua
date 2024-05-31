require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = function(lang, bufnr)
      if vim.api.nvim_buf_line_count(bufnr) >= 5000 then
        return true
      elseif vim.api.nvim_get_option_value("diff", {}) then
        return true
      else
        if vim.g.ufo_enabled == 0 then
          vim.bo.foldmethod = "expr"
          vim.bo.foldexpr = "nvim_treesitter#foldexpr()"
        end
        return false
      end
    end
  },
  indent = {
    enable = true,
  },
}

