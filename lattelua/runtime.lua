loadstring = loadstring or load
unpack = unpack or table.unpack
pack = pack or table.pack
try = function(f, t)
  local r
  if type(f) == 'function' then
    r = { pcall(f) }
  end

  if not r[1] and type(t['catch']) == 'function' then
    t['catch'](r[2] or 'Runtime Error')
    if type(t['finally']) ~= 'function' then
      return r[2] or 'Rintime Error' 
    end
  end

  if type(t['finally']) == 'function' then
    t['finally'](r)
  end

  return unpack(r, 2)
end
local compile = require("lattelua.compile")
local parse = require("lattelua.parse")
local concat, insert, remove
do
  local _obj_0 = table
  concat, insert, remove = _obj_0.concat, _obj_0.insert, _obj_0.remove
end
local split, dump, get_options, unpack, setfenv
do
  local _obj_0 = require("lattelua.util")
  setfenv = setfenv or _obj_0.setfenv
  split, dump, get_options, unpack = _obj_0.split, _obj_0.dump, _obj_0.get_options, _obj_0.unpack
end
local lua = {
  loadstring = loadstring,
  load = load
}
local lattelua, dirsep, line_tables, create_lattepath, to_lua, latte_loader, loadstring, readfile, loadfile, dofile, insert_loader, remove_loader
dirsep = "/"
line_tables = require("lattelua.line_tables")
create_lattepath = function(package_path)
  local lattepaths
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = split(package_path, ";")
    for _index_0 = 1, #_list_0 do
      local _continue_0 = false
      repeat
        local path = _list_0[_index_0]
        local prefix = path:match("^(.-)%.lua$")
        if not (prefix) then
          _continue_0 = true
          break
        end
        local _value_0 = prefix .. ".llua"
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    lattepaths = _accum_0
  end
  return concat(lattepaths, ";")
end
to_lua = function(text, options)
  if options == nil then
    options = { }
  end
  if "string" ~= type(text) then
    local t = type(text)
    return nil, "expecting string (got " .. t .. ")"
  end
  local tree, err = parse.lexer(text)
  if not tree then
    return nil, err
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    return nil, compile.format_error(ltable, pos, text)
  end
  return code, ltable
end
latte_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path
  for path in package.lattepath:gmatch("[^;]+") do
    file_path = path:gsub("?", name_path)
    file = io.open(file_path)
    if file then
      break
    end
  end
  if file then
    local text = file:read("*a")
    file:close()
    local res, err = loadstring(text, "@" .. tostring(file_path))
    if not res then
      error(file_path .. ": " .. err)
    end
    return res
  end
  return nil, "Could not find llua file"
end
loadstring = function(...)
  local options, str, chunk_name, mode, env = get_options(...)
  chunk_name = chunk_name or "=(lattelua.loadstring)"
  local code, ltable_or_err = to_lua(str, options)
  if not (code) then
    return nil, ltable_or_err
  end
  if chunk_name then
    line_tables[chunk_name] = ltable_or_err
  end
  return (lua.loadstring or lua.load)(code, chunk_name, unpack({
    mode,
    env
  }))
end
readfile = function(fname, ...)
  local file, err = io.input(fname or io.stdin)
  if not (file) then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return text, nil
end
loadfile = function(fname, ...)
  local text, err = readfile(fname)
  if not text then
    return nil, err
  end
  return loadstring(text, "@" .. tostring(fname), ...)
end
dofile = function(...)
  local f = assert(loadfile(...))
  return f()
end
insert_loader = function(pos)
  if pos == nil then
    pos = 2
  end
  if not package.lattepath then
    package.lattepath = create_lattepath(package.path)
  end
  local loaders = package.loaders or package.searchers
  for _index_0 = 1, #loaders do
    local loader = loaders[_index_0]
    if loader == latte_loader then
      return false
    end
  end
  insert(loaders, pos, latte_loader)
  return true
end
remove_loader = function()
  local loaders = package.loaders or package.searchers
  for i, loader in ipairs(loaders) do
    if loader == latte_loader then
      remove(loaders, i)
      return true
    end
  end
  return false
end
setupenv = function(...)
  local i = 1
  local mt = {}
  local stack = ... or 2
  local env = debug.getinfo(stack - 1, 'f') or {}

  while true do
    local name, value = debug.getlocal(stack, i)
    if not name then break end
    mt[name] = value
    i = i + 1
  end
  for _, fn in pairs(env) do
    setfenv(fn, setmetatable(mt, {
      __index = _G,
    }))
  end
end
lattelua = setmetatable({
  _NAME = "lattelua",
  insert_loader = insert_loader,
  remove_loader = remove_loader,
  to_lua = to_lua,
  latte_loader = latte_loader,
  dirsep = dirsep,
  dofile = dofile,
  readfile = readfile,
  loadfile = loadfile,
  loadstring = loadstring,
  create_lattepath = create_lattepath
},{
  __call = function(t, code)
    local fn, err = loadstring(code)
    if "function" ~= type(fn) then
      return error(err)
    else
      setfenv(fn, setmetatable(
        {
          setupenv = setupenv
        },
        {__index = _G})
      )
    end

    return fn()
  end
})

return lattelua
