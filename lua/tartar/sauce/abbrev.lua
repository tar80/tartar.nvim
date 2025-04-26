local helper = require('tartar.helper')

return {
  ia = function(word, replaces)
    vim.iter(replaces):each(function(replace)
      vim.keymap.set('ia', replace, word)
    end)
  end,
  ca = function(word, replace)
    vim.validate('replace', replace[1], 'table', 'replace must be table')
    ---@see https://zenn.dev/vim_jp/articles/2023-06-30-vim-substitute-tips
    local getchar = replace[2] and '[getchar(), ""][1].' or ''
    local exp
    if replace[1][2] then
      exp = ('getcmdtype()..getcmdline() ==# ":%s" ? %s"%s" : getcmdtype()..getcmdline() ==# ":\'<,\'>%s" ? %s"%s" : "%s"'):format(
        word,
        getchar,
        helper.replace_lt(replace[1][1]),
        word,
        getchar,
        helper.replace_lt(replace[1][2]),
        word
      )
    else
      exp = string.format('getcmdtype()..getcmdline() ==# ":%s" ? %s"%s" : "%s"', word, getchar, replace[1][1], word)
    end
    vim.keymap.set('ca', word, exp, { expr = true })
  end,
  set = function(self, mode)
    local func = self[mode]
    local iter = vim.iter(self.tbl[mode])
    iter:each(func)
  end,
}
