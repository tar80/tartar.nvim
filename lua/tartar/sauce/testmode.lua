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

  local function _plenary_test_file_do()
    require('plenary.test_harness').test_file(vim.env.TEST_PATH)

    vim.schedule(function()
      if vim.api.nvim_get_option_value('filetype', {}) == 'PlenaryTestPopup' then
        vim.api.nvim_buf_set_keymap(0, 'n', 'q', 'callback', {
          callback = function()
            vim.api.nvim_buf_delete(0, { force = true })
          end,
          desc = 'Overwrite plenary default quit keymap by tartar',
        })
      end
    end)
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
      local filename = bufname:find('init.lua', 1, true) and vim.fs.dirname(bufname) or bufname:gsub('%.lua$', '', 1)
      test_path = ('%s/%s_spec.lua'):format(test_path, util.extract_filename(filename))

      if not vim.uv.fs_stat(test_path) then
        local fd = assert(vim.uv.fs_open(test_path, 'w', 420))
        vim.uv.fs_write(
          fd,
          "local assert = require('luassert')\n"
            .. "local stub = require('luassert.stub')\n"
            .. "local spy = require('luassert.spy')\n"
        )
        vim.uv.fs_close(fd)
      end

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
          _plenary_test_file_do()
        elseif vim.uv.fs_stat(vim.env.TEST_PATH) then
          _plenary_test_file_do()
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
      end, { desc = ('[%s] abort PlenaryTestMode'):format(UNIQUE_NAME) })
    end
  end, {})
end
