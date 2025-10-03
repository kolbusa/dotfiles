function find_dot_claude(wd)
  local dir = wd
  local result = nil
  while dir and dir ~= "" do
    if vim.fn.isdirectory(dir .. "/.claude") == 1 then
      result = dir
    end
    if vim.fn.isdirectory(dir .. "/agent-kb") == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return nil
    end
    dir = parent
  end
  return result
end

require("claudecode").setup({
  terminal_cmd = "/home/tools_ai/anthropic-ai/claude/latest/claude",
  terminal = {
    cwd_provider = function(ctx)
      -- Prefer repo root; fallback to file's directory
      local wd = ctx.file_dir or ctx.cwd
      local cwd = require("claudecode.cwd").git_root(wd) or find_dot_claude(wd) or wd
      return cwd
    end,
  },
})

