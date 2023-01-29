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
vim.o.listchars = "eol:¬,space: ,lead:·,trail:·,nbsp:◇,tab:--→,extends:▸,precedes:◂"
vim.o.number = true
vim.o.numberwidth = 3
vim.o.relativenumber = true
vim.o.signcolumn = "no"
vim.o.wrap = true

vim.cmd [[
  colorscheme jellybeans
]]

require('gitsigns').setup { numhl = true }

vim.cmd [[
  let g:airline_theme='jellybeans'
  let g:airline_mode_map = {
  \   '__'    : '-',
  \   'c'     : 'C',
  \   'i'     : 'I',
  \   'ic'    : 'I',
  \   'ix'    : 'I',
  \   'n'     : 'N',
  \   'multi' : 'M',
  \   'ni'    : 'N',
  \   'no'    : 'N',
  \   'R'     : 'R',
  \   'Rv'    : 'R',
  \   's'     : 'S',
  \   'S'     : 'S',
  \   ''     : 'S',
  \   't'     : 'T',
  \   'v'     : 'V',
  \   'V'     : 'V',
  \   ''     : 'V',
  \ }
  let g:airline_section_a = airline#section#create(['mode'])
  let g:airline_section_b = airline#section#create(['%f'])
  let g:airline_section_c = airline#section#create(['ffenc','%r:%B'])
  let g:airline_section_x = airline#section#create(['filetype'])
  let g:airline_section_y = airline#section#create(['%{get(b:,"gitsigns_head","")}','(','%{get(b:,"gitsigns_status","")}',')'])
  let g:airline_section_z = airline#section#create(['%c:%l/%L'])
]]

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
]]

pcall(vim.cmd, [[
  let g:startify_bookmarks = map(
  \   readfile((!empty($XDG_CONFIG_HOME)?$XDG_CONFIG_HOME:$HOME.'/.config').'/nvim/bookmarks'),
  \   '{split(v:val)[0]:split(v:val)[1]}'
  \ )
]])
