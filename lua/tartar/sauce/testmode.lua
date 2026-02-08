---@class Opts
---@field localleader string
---@field test_key string
---@field abort_mode_key string

---@param UNIQUE_NAME string
---@param opts Opts
return function(UNIQUE_NAME, opts)
  vim.validate('localleader', opts.localleader, 'string', false)
  vim.validate('test_key', opts.test_key, 'string', true)
  vim.validate('abort_mode_key', opts.abort_mode_key, 'string', true)

  local helper = require('tartar.helper')
  local util = require('tartar.util')

  local TEST_DIRECTORIES = { 'test', 'tests', 'spec', 'specs' }

  local function _get_plenary_path()
    local ok, _ = pcall(require, 'plenary')
    if ok then
      local rtp = vim.split(vim.go.runtimepath, ',')
      return vim.iter(rtp):find(function(path)
        return path:find('plenary.nvim', 1, true)
      end)
    end
  end

  vim.api.nvim_create_user_command('PlenaryTestMode', function()
    if vim.bo.filetype == '' then
      vim.notify('Not applicable to scratch buffers', vim.log.levels.ERROR, { title = 'PlenaryTestMode' })
      return
    end
    local plenary_path = _get_plenary_path()
    if not plenary_path then
      vim.notify('Could not find planery.nvim', vim.log.levels.ERROR, { title = 'PlenaryTestMode' })
    end
    local root = assert(vim.uv.cwd())
    local bufname = vim.api.nvim_buf_get_name(0)
    local is_windows = helper.is_windows()
    local test_path ---@type string
    if not bufname:find('_spec.lua$') then
      local test_dirnames = vim.fs.find(TEST_DIRECTORIES, { limit = 1, type = 'directory', path = root })
      if #test_dirnames == 0 then
        test_path = ('%s/tests'):format(vim.fs.normalize(root, { win = is_windows }))
        assert(vim.uv.fs_mkdir(test_path, 755))
      else
        test_path = test_dirnames[1]
      end
      test_path = ('%s/%s'):format(test_path, util.extract_filename(bufname):gsub('%.lua$', '_spec.lua'))
      vim.cmd([[tabedit %]])
      vim.b.localleader = opts.localleader
      vim.cmd(([[bot split %s]]):format(test_path))
    end
    vim.b.localleader = opts.localleader
    vim.env.PLENARY_PATH = plenary_path
    vim.env.TEST_PATH = test_path or bufname

    if opts.test_key then
      vim.keymap.set('n', opts.test_key, function()
        local _bufname = vim.api.nvim_buf_get_name(0)
        if _bufname:find('_spec.lua$') then
          vim.env.TEST_PATH = _bufname
          require('plenary.test_harness').test_file(vim.env.TEST_PATH)
        elseif vim.uv.fs_stat(vim.env.TEST_PATH) then
          require('plenary.test_harness').test_file(vim.env.TEST_PATH)
        else
          vim.notify('Path not found.', vim.log.levels.ERROR, { 'PlenaryTestHarness' })
        end
      end, { desc = ('[%s] plenary test current file'):format(UNIQUE_NAME) })
    end

    if opts.abort_mode_key then
      vim.keymap.set('n', opts.abort_mode_key, function()
        vim.b.localleader = nil
        vim.env.PLENARY_PATH = nil
        vim.env.TEST_PATH = nil
        vim.api.nvim_del_keymap('n', opts.test_key)
        vim.api.nvim_del_keymap('n', opts.abort_mode_key)
        vim.notify('Aborted PlenaryTestMode.', vim.log.levels.INFO, { 'PlenaryTestMode' })
      end, { desc = ('[%s] aborted PlenaryTestMode'):format(UNIQUE_NAME) })
    end
  end, {})
end
