-- -- Enable verbose logs
-- vim.cmd [[
--   autocmd VimEnter * set verbosefile = ~/.cache/nvim.log
--   autocmd VimEnter * set verbose = 15
-- ]]

-- Default configs
vim.o.autoindent = true
vim.o.backspace = "indent,eol,start"
vim.o.cindent = true
vim.o.clipboard = "unnamedplus"
vim.o.expandtab = true
vim.o.history = 50
vim.o.ignorecase = true
vim.o.scrolloff = 999
vim.o.shiftwidth = 4
vim.o.smartcase = true
vim.o.smarttab = true
vim.o.softtabstop = -1
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabstop = 4
vim.o.timeoutlen = 500
vim.o.updatetime = 1000
vim.opt.mouse = "a"

vim.o.background = "dark"
vim.o.cursorline = true
vim.o.list = true
vim.o.listchars =
  "eol:↲,space: ,lead:·,trail:·,nbsp:◇,tab:--→,extends:▸,precedes:◂"
vim.o.number = true
vim.o.numberwidth = 3
vim.o.relativenumber = true
vim.o.signcolumn = "no"
vim.o.wrap = true

-- Theme
vim.cmd [[
  colorscheme jellybeans
]]

-- Icons
vim.cmd [[
  let g:webdevicons_enable_airline_statusline = 0
]]

-- Git
require('gitsigns').setup { numhl = true }
vim.cmd [[
  autocmd BufEnter * silent! Gcd
]]

-- Status
vim.cmd [[
  let g:airline_theme = 'jellybeans'
  let g:airline_mode_map = {
  \   '__'    : '-',
  \   'c'     : 'C',
  \   'i'     : 'I',
  \   'ic'    : 'I',
  \   'ix'    : 'I',
  \   'multi' : 'M',
  \   'n'     : 'N',
  \   'ni'    : 'N',
  \   'no'    : 'N',
  \   'R'     : 'R',
  \   'Rv'    : 'R',
  \   's'     : 'S',
  \   'S'     : 'S',
  \   't'     : 'T',
  \   'v'     : 'V',
  \   'V'     : 'V',
  \   ''     : 'S',
  \   ''     : 'V',
  \ }
  let g:airline_section_a = airline#section#create([
  \   'mode',
  \ ])
  let g:airline_section_b = airline#section#create([
  \   '%{WebDevIconsGetFileTypeSymbol()} ',
  \   '%{resolve(expand("%"))}',
  \ ])
  let g:airline_section_c = airline#section#create([
  \   airline#parts#ffenc() !=? ''
  \     ? '%{WebDevIconsGetFileFormatSymbol()." ".&fenc}'
  \     : '',
  \   '%r',
  \ ])
  let g:airline_section_x = airline#section#create([
  \   '%{get(b:,"gitsigns_status","")}',
  \ ])
  let g:airline_section_y = airline#section#create([
  \   '%{get(b:,"gitsigns_head","")}',
  \ ])
  let g:airline_section_z = airline#section#create([
  \   '%B@%c:%l/%L',
  \ ])
]]

-- Whitespace
vim.cmd [[
  let g:airline#extensions#whitespace#symbol = ''
  let g:better_whitespace_enabled = 0
  let g:strip_whitespace_on_save = 1
  let g:strip_whitespace_confirm = 0
  let g:strip_whitelines_at_eof = 1
]]

-- NERD tree
vim.cmd [[
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
  \   quit |
  \ endif

  let g:NERDTreeGitStatusIndicatorMapCustom = {
  \   'Modified'  :'~',
  \   'Staged'    :'+',
  \   'Untracked' :'*',
  \   'Renamed'   :'>',
  \   'Unmerged'  :'!',
  \   'Deleted'   :'-',
  \   'Dirty'     :'~',
  \   'Unknown'   :'?',
  \ }
]]

-- Startify
vim.cmd [[
  let g:startify_custom_header = [
  \   '   #####################################',
  \   '   #     __      ___                   #',
  \   '   #    |  |    /  / __                #',
  \   '   #    |  |   /  / |__|  ________     #',
  \   '   #    |  |  /  /   __  |        |    #',
  \   '   #    |  | /  /   |  | |  |  |  |    #',
  \   '   #    |  |/  /    |  | |  |  |  |    #',
  \   '   #    |     /     |__| |__|__|__|    #',
  \   '   # ===|    /======================== #',
  \   '   #    |___/           nix++ edition  #',
  \   '   #                                   #',
  \   '   #####################################',
  \ ]

  let g:startify_list_order = [ 'bookmarks', 'dir' ]

  function! StartifyEntryFormat()
    return 'WebDevIconsGetFileTypeSymbol(absolute_path)."  ".entry_path'
  endfunction
]]

pcall(vim.cmd, [[
  let g:startify_bookmarks = map(
  \   readfile((!empty($XDG_CONFIG_HOME)?$XDG_CONFIG_HOME:$HOME.'/.config').'/nvim/bookmarks'),
  \   '{split(v:val)[0]:split(v:val)[1]}'
  \ )
]])

-- Startup
vim.cmd [[
  autocmd StdinReadPre * let s:std_in = 1
  autocmd VimEnter * if !exists('s:std_in') |
  \ NERDTree | wincmd p | endif
  autocmd VimEnter * if !exists('s:std_in') && (argc() == 0 || isdirectory(argv()[0])) |
  \ Startify | endif
]]

-- Others
require("virt-column").setup { char = "│", virtcolumn = "80,120" }
vim.cmd [[
  nnoremap q <Nop>
]]
