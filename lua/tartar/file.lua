local M = {}

---Writes data to a file. Creates parent directories if they don't exist.
---@param path string The path to the file.
---@param contents string|string[] The contents to write to the file.
---@return boolean ok, string? message
function M.write(path, contents)
  local dir = vim.fs.dirname(path)
  local stat = vim.uv.fs_stat(dir)
  if not stat or stat.type ~= 'directory' then
    local ok = pcall(vim.fn.mkdir, dir, 'p')
    if not ok then
      return false, 'Failed to create directory: ' .. dir
    end
  end
  local handle, message = io.open(path, 'w+')
  if not handle then
    return false, message
  end
  if type(contents) == 'table' then
    ---@cast contents table
    contents = table.concat(contents, '\n')
  end
  ---@cast contents string
  handle:write(contents)
  handle:close()

  return true, 'Created the file.'
end

return M
