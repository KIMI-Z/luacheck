local utils = {}

utils.dir_sep = package.config:sub(1,1)
utils.is_windows = utils.dir_sep == "\\"

-- Returns all contents of file(path or file handler) or nil. 
function utils.read_file(file)
   local res

   return pcall(function()
      local handler = type(file) == "string" and io.open(file, "rb") or file
      res = assert(handler:read("*a"))
      handler:close()
   end) and res or nil
end

-- luacheck: push
-- luacheck: compat
if _VERSION:find "5.1" then
   -- Loads Lua source string in an environment, returns function or nil.
   function utils.load(src, env)
      local func = loadstring(src)

      if func then
         return setfenv(func, env)
      end
   end
else
   -- Loads Lua source string in an environment, returns function or nil.
   function utils.load(src, env)
      return load(src, nil, "t", env)
   end
end
-- luacheck: pop

-- Parses rockspec-like source, returns data or nil. 
local function capture_env(src, env)
   env = env or {}
   local func = utils.load(src, env)
   return func and pcall(func) and env
end

-- Loads config containing assignments to global variables from path. 
-- Returns config table or nil and error message("I/O" or "syntax"). 
function utils.load_config(path, env)
   local src = utils.read_file(path)

   if not src then
      return nil, "I/O"
   end

   local cfg = capture_env(src, env)

   if not cfg then
      return nil, "syntax"
   end

   return cfg
end

function utils.array_to_set(array)
   local set = {}

   for index, value in ipairs(array) do
      set[value] = index
   end

   return set
end

function utils.concat_arrays(array)
   local res = {}

   for _, subarray in ipairs(array) do
      for _, item in ipairs(subarray) do
         table.insert(res, item)
      end
   end

   return res
end

function utils.update(t1, t2)
   for k, v in pairs(t2) do
      t1[k] = v
   end

   return t1
end

local class_metatable = {}

function class_metatable.__call(class, ...)
   local obj = setmetatable({}, class)

   if class.__init then
      class.__init(obj, ...)
   end

   return obj
end

function utils.class()
   local class = setmetatable({}, class_metatable)
   class.__index = class
   return class
end

utils.Stack = utils.class()

function utils.Stack:__init()
   self.size = 0
end

function utils.Stack:push(value)
   self.size = self.size + 1
   self[self.size] = value
   self.top = value
end

function utils.Stack:pop()
   local value = self[self.size]
   self[self.size] = nil
   self.size = self.size - 1
   self.top = self[self.size]
   return value
end

local function error_handler(err)
   if type(err) == "table" then
      return false
   else
      return tostring(err) .. "\n" .. debug.traceback()
   end
end

-- Calls f with arg, returns what it does.
-- If f throws a table, returns nil.
-- If f throws not a table, rethrows.
function utils.pcall(f, arg)
   local function task()
      return f(arg)
   end

   local ok, res = xpcall(task, error_handler)

   if ok then
      return res
   elseif not res then
      return nil
   else
      error(res, 0)
   end
end

local function ripairs_iterator(array, i)
   if i == 1 then
      return nil
   else
      i = i - 1
      return i, array[i]
   end
end

function utils.ripairs(array)
   return ripairs_iterator, array, #array + 1
end

function utils.after(str, pattern)
   local _, last_matched_index = str:find(pattern)

   if last_matched_index then
      return str:sub(last_matched_index + 1)
   end
end

function utils.strip(str)
   local _, last_start_space = str:find("^%s*")
   local first_end_space = str:find("%s*$")
   return str:sub(last_start_space + 1, first_end_space - 1)
end

-- `sep` must be nil or a single character. Behaves like python's `str.split`.
function utils.split(str, sep)
   local parts = {}
   local pattern

   if sep then
      pattern = sep .. "([^" .. sep .. "]*)"
      str = sep .. str
   else
      pattern = "%S+"
   end

   for part in str:gmatch(pattern) do
      table.insert(parts, part)
   end

   return parts
end

return utils
