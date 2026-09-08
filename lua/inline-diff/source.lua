local M = {}

M._root_cache = {}

local function normalize(spec)
  if spec == nil then
    return { type = "git", ref = "HEAD" }
  end
  if type(spec) == "string" then
    if spec == "staged" then
      return { type = "index" }
    end
    return { type = "git", ref = spec }
  end
  if type(spec) ~= "table" then
    error("inline-diff source must be a ref string or source table")
  end

  local source_type = spec.type or spec.kind
  if source_type == "git" then
    return { type = "git", ref = spec.ref or "HEAD" }
  elseif source_type == "index" then
    return { type = "index" }
  elseif source_type == "empty" then
    return { type = "empty" }
  end
  error("unknown inline-diff source: " .. tostring(source_type))
end

M.normalize = normalize

function M.key(spec)
  spec = normalize(spec)
  if spec.type == "git" then
    return "git:" .. spec.ref
  end
  return spec.type
end

function M.describe(spec)
  spec = normalize(spec)
  if spec.type == "git" then
    return spec.ref
  elseif spec.type == "index" then
    return "staged"
  end
  return "empty"
end

local function split_lines(stdout)
  local lines = vim.split(stdout, "\r?\n")
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function with_root(filepath, callback)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local cached_root = M._root_cache[dir]
  if cached_root then
    callback(cached_root)
    return
  end

  vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true, cwd = dir }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        callback(nil, "not a git repo")
        return
      end
      local root = vim.trim(obj.stdout)
      M._root_cache[dir] = root
      callback(root)
    end)
  end)
end

local function show_path(root, relpath, revision, callback)
  vim.system({ "git", "show", revision .. ":" .. relpath }, { text = true, cwd = root }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        callback(split_lines(obj.stdout))
      else
        -- A valid revision may not contain this path. Treat that as an empty
        -- snapshot so newly added and untracked files render as additions.
        callback({})
      end
    end)
  end)
end

local function show_git_revision(root, relpath, ref, callback)
  vim.system({ "git", "rev-parse", "--verify", ref .. "^{commit}" }, { text = true, cwd = root }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        -- HEAD is allowed to be unborn in a newly initialised repository.
        if ref == "HEAD" then
          callback({})
        else
          callback(nil, "git ref not found: " .. (obj.stderr or ""))
        end
        return
      end
      show_path(root, relpath, ref, callback)
    end)
  end)
end

function M.get(filepath, spec, callback)
  spec = normalize(spec)
  if spec.type == "empty" then
    vim.schedule(function()
      callback({})
    end)
    return
  end

  with_root(filepath, function(root, err)
    if not root then
      callback(nil, err)
      return
    end

    local relpath = filepath:sub(#root + 2):gsub("\\", "/")
    if spec.type == "index" then
      show_path(root, relpath, ":0", callback)
    else
      show_git_revision(root, relpath, spec.ref, callback)
    end
  end)
end

return M
