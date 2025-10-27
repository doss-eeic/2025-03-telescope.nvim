local Path = require("plenary.path")
local M = {}

local db_file = vim.fn.stdpath('data') .. '/telescope_frecency.json'
local db = nil

local function load_db()
  if db then return db end

  local p = Path:new(db_file)
  if not p:exists() then
    db = {}
    return db
  end
  local ok, content = pcall(function() return p:read() end)
  if not ok or content == nil or content == "" then
    db = {}
    return db
  end

  local decode_ok, decoded = pcall(vim.fn.json_decode, content)
  if decode_ok and type(decoded) == "table" then
    db = decoded
  else
    vim.notify("failed to decode DB", vim.log.levels.WARN)
    db = {}
  end

  return db
end

local function save_db()
  if not db then return end
  local p = Path:new(db_file)
  p:parent():mkdir({ parents = true })

  local ok, err = pcall(function()
    p:write(vim.fn.json_encode(db))
  end)
  if not ok then
    local data = vim.fn.json_encode(db)
    local lines = { data }
    local wrote, write_err = pcall(function() vim.fn.writefile(lines, db_file, "b") end)
    if not wrote then
      vim.notify("failed to save DB" .. tostring(write_err), vim.log.levels.WARN)
    end
  end
end

function M.inc(path)
  load_db()
  db[path] = db[path] or { count = 0, last = 0 }
  db[path].count = (db[path].count or 0) + 1
  db[path].last = os.time()
  save_db()
end

function M.score(path)
  load_db()
  local meta = db[path]
  if not meta then return 0 end
  local cnt = meta.count or 0
  local days = (os.time() - (meta.last or 0)) / 86400
  if days < 0 then days = 0 end
  local rec = 1 / (1 + days)
  return cnt + rec
end

function M.load() return load_db() end

return M