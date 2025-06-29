# tartar.nvim

tartar.nvim is a library that consolidates a set of functions frequently used
in the tar80's projects. While each project does not necessarily require tartar,
when it is available, it is preferred to use this library. This approach helps
avoid redundant loading of the same functions and allows for resource sharing.

tartar.nvim includes common resources used in the following projects.

- [Fret.nvim](https://github.com/tar80/fret.nvim)
- [Matchwith.nvim](https://github.com/tar80/matchwith.nvim)
- [Rereope.nvim](https://github.com/tar80/rereope.nvim)
- [Staba.nvim](https://github.com/tar80/staba.nvim)

## Configutarion

setup is required when using the module sharing function.

```lua
require('tartar').setup()
```

## Secret sauce

`tartar.sauce` provides some really trivial little convenience functions.
This can be used independently regardless of the module sharing function.

```lua
local sauce = require('tartar.sauce')
```

- **smart foldclose**

Maps the `zc` key to a smart foldclose function. If there's no `v:foldlevel`
defined at the cursor's current line, it will set `vim.lsp.foldexpr()` if LSP is enabled,
or `vim.treesitter.foldexpr()` if Treesitter is enabled. Otherwise, it sends `zc` normally.

```lua
---@param mod string "lsp"|"treesitter"|"both" Which module to target
---@param initial_time integer Wait time when setting vim.lsp.foldexpr()
sauce.map_smart_zc(mod:"both", initial_time:250)
```

![smart_zc](https://github.com/user-attachments/assets/34f218e6-18ad-47bc-a308-129998e5d7f3)

- **foldtext**

Provides easy and unobtrusive foldtext.

This function is based on [tamton-aquib/essentials.nvim](https://github.com/tamton-aquib/essentials.nvim)

```lua
---@param separator_spec Separator preceding the total fold count.
sauce.foldtext(separator_spec:"»")
```

- **align**

Provides an extremely simple align function. Aligns the selected range using
vim.regex() matches.

This function is based on [RRethy/nvim-align](https://github.com/RRethy/nvim-align)

> [!CAUTION]
>
> - If you delete characters or move the cursor in the input bar using methods other
>   than `<Del>`, `<BS>`, `<C-w>`, `<C-u>`, `<Left>`, and `<Right>`, a bug will occur.
>   It seems unlikely that strict measures can be taken easily, so this is the specification.
> - Due to circumstances, grouping is not possible. `[` is always replaced with `\[`.

```lua
---@param hlgroup_spec Hlgroup used for alignment blanks
sauce.align(hlgroup_spec:"IncSearch")

vim.keymap.set('x', 'aa', function()
  reutn sauce.align('IncSearch')
end, { desc = 'Tartar align' })
```

![align](https://github.com/user-attachments/assets/425b1c38-004a-4b1b-882d-638161fc744f)

- **abbreviations**

Extend abbreviation functionality. Insert mode allows you to set multiple matches
for a single word, as is the original spelling correction feature. In command mode,
it acts as a command snippet.  
First set the `abbrev.tbl` and register it with `abbrev:set()` method.

```lua
sauce.abbrev.tbl = {
  -- Insert-mode abbreviations
  ---@type {[string]: string[]}
  ia = {
    ['function'] = { 'funcion', 'fuction' },
    ['return'] = { 'reutnr', 'reutrn', 'retrun' },
    ['true'] = 'treu'
  },
  -- Command-mode snippets
  ---@alias Command     string  Commandline snippet
  ---@alias Search      string  Search-command snippet
  ---@alias IgnoreSpace boolean Omit a space after command
  ---@type {[string]: [{{Command, Search}, IgnoreSpace}]}
  ca = {
    es = { { 'e<Space>++enc=cp932<Space>++ff=dos<CR>' } },
    e8 = { { 'e<Space>++enc=utf-8<CR>' } },
    eu = { { 'e<Space>++enc=utf-16le<Space>++ff=dos<CR>' } },
    sc = { { 'set<Space>scb<Space><Bar><Space>wincmd<Space>p<Space><Bar><Space>set<Space>scb<CR>' } },
    scn = { { 'set<Space>noscb<CR>' } },
    dd = { { 'diffthis<Bar>wincmd<Space>p<Bar>diffthis<Bar>wincmd<Space>p<CR>' } },
    dof = { { 'diffoff!<CR>' } },
    -- DiffOrg
    dor = {
      {
        'tab<Space>split<Bar>vert<Space>bel<Space>new<Space>difforg<Bar>set<Space>bt=nofile<Bar>r<Space>++edit<Space>#<Bar>0d_<Bar>windo<Space>diffthis<Bar>wincmd<Space>p<CR>',
      },
    },
    ht = { { 'so<Space>$VIMRUNTIME/syntax/hitest.vim' } },
    ct = { { 'so<Space>$VIMRUNTIME/syntax/colortest.vim' } },
    s = { { '%s//<Left>', 's//<Left>' }, true },
    ss = { { '%s///<Left>', 's///<Left>' }, true },
  },
}
sauce.abbrev:set('ia')
sauce.abbrev:set('ca')
```

- **instant bench**

Run the luascript benchmark instantly. It provides three functions for benchmark
execution and a total of five methods for inserting and clearing templates.

use it like this:

```lua
local bench = require('tartar.sauce.bench')
local result = bench.run(10000, function()
    return vim.api.nvim_win_get_buf(0)
end, function()
    return vim.fn.bufnr()
end)
vim.print(result)

-- This executes `print(result)` with the same content but no return value.
bench.print(10000, function()
    return vim.api.nvim_win_get_buf(0)
end, function()
    return vim.fn.bufnr()
end)
```

If you load a `insert_template()` you can run mark range.  
`:'a,'bsource %`

```lua
    -- Run the benchmark and return the results
    ---@generic Ret any
    ---@alias ResultTable {[integer]: [number, Ret]}
    ---@param loop_count integer
    ---@param ... (fun():Ret)[]
    ---@return ResultTable
    sauce.bench.run(loop_count, ...)

    -- Run the benchmark and `print` the results
    ---@return nil
    sauce.bench.print(loop_count, ...)

    -- Run the benchmark and `vim.notify` the results
    ---@return nil
    sauce.bench.notify(loop_count, ...)

    -- Insert template and mark the start and end lines of the template
    ---@param is_notify boolean If `true` is specified, notify() is set. If `false`, set print().
    ---@param start_mark Mark name of the template start line
    ---@param end_mark Mark name of the template end line
    sauce.bench.insert_template(is_notify, start_mark, end_mark)

    -- Clear template range
    sauce.bench.clear()
```

- **live rectangle replacement**

Immediate feedback on replacement status when selecting a rectangle.

> [!CAUTION]
>
> It's full of bugs.

```lua
---@class LiveReplaceOpts
---@field after? boolean Insert after cursor position
---@field fill? boolean Fill virtual column with spaces
---@field higroup? string Highlight for cursor position
---@field is_replace? boolean Whether to replace the selected range
---@field send_key? boolean Set it to true for keys that change the selection range itself, such as the C or S key.

---@alias LiveReplace
---@param key string
---@param opts LiveReplaceOpts
---@type LiveRectangleReplacement
local live_rectangle_replace = sauce.live_replace()

vim.keymap.set('v', 'I', function()
    live_rectangle_replace('I')
end, { desc = 'Tartar live_replace' })

vim.keymap.set('v', 'A', function()
    live_rectangle_replace('A', { after = true, fill = true })
end, { desc = 'Tartar live_replace' })

vim.keymap.set('v', 'c', function()
    live_rectangle_replace('c', { is_replace = true, higroup = 'Visual' })
end, { desc = 'Tartar live_replace' })

vim.keymap.set('v', 'C', function()
    live_rectangle_replace('C', { send_key = true })
end, { desc = 'Tartar live_replace' })
```

- **plug key**

This is a helper function to help register submode keys.
Facilitates the registration of keys like those introduced in the article below.

[Vim で折り返し行を簡単に移動できるサブモード・テクニック](https://zenn.dev/mattn/articles/83c2d4c7645faa)

```lua
---@param mode string Mode short name
---@param name string Plug-key name
---@param prefix_key string A trigger key
---@param is_repeatable boolean Wheter to use key repeat
---multiple returns
---@return fun(keys: string|string[]|{string,string|function}[]):nil
---@return fun(keys: string|string[]|{string,string}[], converted_key?: string):nil
sauce.plugkey(mode, name, prefix_key, is_repeatable)
```

There are four ways to specify the key mappings:

1. **Specifying allowed keys:**  
   For example, if you set key mappings like this:

   ```lua
   vim.keymap.set("n", "q", "<Plug>(unique_q)", {})
   vim.keymap.set('n', '<Plug>(unique_q)q', function()
    return vim.fn.reg_recording() == '' and 'qq' or 'q'
   end, { expr = true })
   ```

   Other keys starting with `q` will become unusable. Therefore, you need to add
   the following key mappings as well:

   ```lua
   vim.keymap.set("n", "<Plug>(unique_q):", "q:", {})
   vim.keymap.set("n", "<Plug>(unique_q)/", "q/", {})
   vim.keymap.set("n", "<Plug>(unique_q)?", "q?", {})
   ```

   `plugkey` supports registering these allowed keys.

   ```lua
   local function toggle_recording()
     return vim.fn.reg_recording() == '' and 'qq' or 'q'
   end
   local unique_q = sauce.plugkey('n', 'unique_q', 'q')
   ---@param keys string|(string|{string,function})[]
   unique_q({ ':', '/', '?', { 'q', toggle_recording } })
   ```

1. **Enabling continuous key input, such as `gj` becoming `gjjjjj` or `zl` becoming `zllll`:**  
   In this pattern, a table is specified as an argument to the closure function.

   These are submodes for moving the lap line:

   ```lua
   vim.keymap.set('n', 'gj', 'gj<Plug>(repeatable_g)')
   vim.keymap.set('n', 'gk', 'gk<Plug>(repeatable_g)')
   vim.keymap.set('n', '<Plug>(repeatable_g)j', 'gj<Plug>(repeatable_g)')
   vim.keymap.set('n', '<Plug>(repeatable_g)k', 'gh<Plug>(repeatable_g)')


   local repeatable_g = sauce.plugkey('n', 'repeatable_g', 'g', true)
   ---@param keys string|string[]
   repeatable_g({ 'j', 'k' })
   ```

   These are submodes for horizontal scrolling:

   ```lua
   vim.keymap.set('n', 'zh', 'zh<Plug>(repeatable_z)')
   vim.keymap.set('n', 'zl', 'zl<Plug>(repeatable_z)')
   vim.keymap.set('n', '<Plug>(repeatable_z)h', 'zh<Plug>(repeatable_z)')
   vim.keymap.set('n', '<Plug>(repeatable_z)l', 'zl<Plug>(repeatable_z)')


   local repeatable_z = sauce.plugkey('n', 'repeatable_z', 'z', true)
   ---@param keys string|string[]
   repeatable_z({ 'h', 'l' })
   ```

1. **Enabling continuous key input. Executes the key you type and another key**  
   In this pattern, a table is specified as an argument to the closure function.  
   Additionally, for the table element, specify a tuple of {"input key", "execution key"}

   These are submodes for moving window frames:

   ```lua
    vim.keymap.set('n', '<Space>-', '<C-w>-<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Space>;', '<C-w>+<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Space>,', '<C-w><<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Space>.', '<C-w>><Plug>(replaceable_space)')
    vim.keymap.set('n', '<Plug>(replaceable_space)-', '<C-w>-<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Plug>(replaceable_space);', '<C-w>+<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Plug>(replaceable_space),', '<C-w><<Plug>(replaceable_space)')
    vim.keymap.set('n', '<Plug>(replaceable_space).', '<C-w>><Plug>(replaceable_space)')


    local replaceable_space = sauce.plugkey('n', 'replaceable_space', '<Space>', true)
   ---@param keys {string,string}[]
    replaceable_space({ { '-', '<C-w>-' }, { ';', '<C-w>+' }, { ',', '<C-w><' }, { '.', '<C-w>>' } })
   ```

1. **Sending a different key after the same key is entered consecutively:**  
   In this pattern, the first argument of the closure function specifies the
   input key, and the second argument specifies the key to be sent on subsequent inputs.

   These are submodes that moves within the screen at first, and moves between
   pages from the second time onwards.

   ```lua
   vim.keymap.set('n', 'H', 'H<Plug>(remapping_H)')
   vim.keymap.set('n', '<Plug>(remapping_H)H', '<PageUp>H<Plug>(remapping_H)')

   local remapping_H = sauce.plugkey('n', 'remapping_H', 'H', true)
   ---@fun(key:string, converted_key:string)
   remapping_H('H', '<PageUp>H')



   vim.keymap.set('n', 'L', 'L<Plug>(remapping_L)')
   vim.keymap.set('n', '<Plug>(remapping_L)L', '<PageDown>L<Plug>(remapping_L)')

   local remapping_L = sauce.plugkey('n', 'remapping_L', 'L', true)
   ---@fun(key:string, converted_key:string)
   remapping_L('L', '<PageDown>L')
   ```

- **testmode**

Supports running plenary tests. Loading this module sets the user command `PlenaryTestMode`.  
`PlenaryTestMode` opens the file `root/tests/name_spec.lua` corresponding to
the executed buffer in a tab. If `root/tests` does not exist, it will be created.
Also, `localleader` is set to the buffer where the test file was opened.
The local reader is registered with a key to run `plenary.test_harness.test_file()`.

> [!CAUTION]
>
> This module depends on plenary.nvim.

```lua
---@class TestModeOpts
---@field localleader string localleader set to the buffer that opened the test file
---@field test_key string Specifies the key to run plenary.test_harness.test_file()

---@param opts TestModeOpts
sauce.testmode(opts)

-- For example, you can set it like this
sauce.testmode({localleader = '\\', test_key = '<LocalLeader><LocalLeader>'})
```
