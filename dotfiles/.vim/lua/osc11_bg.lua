-- lua/osc11_bg.lua
-- Periodically query terminal background (OSC 11) and toggle 'background'.

local M = {}

-- Default config
local config = {
  period_ms = 2000,          -- how often to poll
  luma_threshold = 0.5,      -- cutoff between light/dark
  tmux_passthrough = true,   -- wrap OSC in tmux passthrough if inside tmux
  on_change = nil,           -- optional callback(new_bg, rgb)
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- --- helpers ---
local function wrap_tmux(payload)
  payload = payload:gsub("\x1b", "\x1b\x1b")
  return "\x1bPtmux;" .. payload .. "\x1b\\"
end

local function tty_write(bytes)
  if config.tmux_passthrough then
    bytes = wrap_tmux(bytes)
  end
  io.write(bytes)
  io.flush()
end

local function read_osc_reply(timeout_ms)
  local start = vim.loop.now()
  local buf, saw_esc = {}, false
  while (vim.loop.now() - start) < timeout_ms do
    local n = vim.fn.getchar(0)
    if n ~= 0 and n ~= -1 then
      local ch = type(n) == "number" and vim.fn.nr2char(n) or n
      buf[#buf + 1] = ch
      if ch == "\x07" then break
      elseif ch == "\x1b" then saw_esc = true
      elseif saw_esc and ch == "\\" then break
      else saw_esc = false end
    else
      vim.wait(5, function() return false end)
    end
  end
  return table.concat(buf)
end

local function parse_rgb(reply)
  local payload = reply:match("\x1b%]11;([^\x07\x1b]*)")
  if not payload then return nil end
  local R4,G4,B4 = payload:match("^rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)$")
  if R4 then
    local function d(s) return tonumber(s:sub(1,2),16) end
    return { r=d(R4), g=d(G4), b=d(B4) }
  end
  local R2,G2,B2 = payload:match("^#(..)(..)(..)$")
  if R2 then return { r=tonumber(R2,16), g=tonumber(G2,16), b=tonumber(B2,16) } end
end

local function luma(rgb)
  local function lin(c) c=c/255; return (c<=0.04045) and (c/12.92) or ((c+0.055)/1.055)^2.4 end
  local R,G,B = lin(rgb.r), lin(rgb.g), lin(rgb.b)
  return 0.2126*R + 0.7152*G + 0.0722*B
end

local function decide_bg(rgb)
  if not rgb then return nil end
  return (luma(rgb) >= config.luma_threshold) and "light" or "dark"
end

local function query_background(timeout_ms)
  tty_write("\x1b]11;?\x07")
  local reply = read_osc_reply(timeout_ms or 250)
  local rgb = parse_rgb(reply or "")
  return decide_bg(rgb), rgb, reply
end

-- --- main loop ---
local last_bg, timer = nil, nil

function M.start()
  if timer then return end
  timer = vim.loop.new_timer()
  timer:start(0, config.period_ms, function()
    vim.schedule(function()
      local bg, rgb = query_background(config.timeout_ms)
      if not bg then return end
      if bg ~= last_bg or vim.o.background ~= bg then
        last_bg = bg
        vim.o.background = bg
        if type(config.on_change) == "function" then pcall(config.on_change, bg, rgb) end
      end
    end)
  end)
end

function M.stop()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

return M
