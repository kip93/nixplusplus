# This file is part of Nix++.
# Copyright (C) 2023 Leandro Emmanuel Reina Kiperman.
#
# Nix++ is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Nix++ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{ features, pkgs, self, ... }:
with pkgs; ''
  -- -- Enable verbose logs
  -- vim.cmd [[
  --   autocmd VimEnter * set verbosefile = ~/.cache/nvim.log
  --   autocmd VimEnter * set verbose = 15
  -- ]]

  -- Default configs
  vim.o.autoindent = true
  vim.o.backspace = "indent,eol,start"
  vim.o.backup = false
  vim.o.cindent = true
  vim.o.clipboard = "unnamedplus"
  vim.o.confirm = true
  vim.o.expandtab = true
  vim.o.history = 50
  vim.o.ignorecase = true
  vim.o.incsearch = true
  vim.o.scrolloff = 999
  vim.o.shiftwidth = 4
  vim.o.smartcase = true
  vim.o.smarttab = true
  vim.o.softtabstop = -1
  vim.o.splitbelow = true
  vim.o.splitright = true
  vim.o.tabstop = 4
  vim.o.timeoutlen = 500
  vim.o.updatetime = 200
  vim.o.visualbell = true
  vim.o.writebackup = false
  vim.opt.mouse = "a"

  vim.o.background = "dark"
  vim.o.cursorline = true
  vim.o.list = true
  vim.o.listchars =
    "eol:↲,lead:·,trail:·,nbsp:◇,tab:--→,extends:▸,precedes:◂"
  vim.o.number = true
  vim.o.numberwidth = 3
  vim.o.relativenumber = true
  vim.o.signcolumn = "yes"
  vim.o.wrap = true

  -- Theme
  vim.cmd [[
    function! s:tweak_jellybeans()
      highlight GitSignsChangeNr ctermfg=110
    endfunction
    autocmd! ColorScheme jellybeans call s:tweak_jellybeans()
    colorscheme jellybeans
  ]]

  require("transparent").setup ({
    enable = true,
    extra_groups = { },
    exclude = { },
  })
  require("virt-column").setup { char = "│", virtcolumn = "80,120" }

  -- Icons
  vim.cmd [[
    let g:webdevicons_enable_airline_statusline = 0
  ]]

  -- Git
  require('gitsigns').setup {
    signcolumn = false,
    numhl = true,
  }
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
    \   "\x13"  : 'S',
    \   "\x16"  : 'V',
    \ }
    let g:airline_section_a = airline#section#create([
    \   'mode',
    \   '%{PencilMode()}'
    \ ])
    let g:airline_section_b = airline#section#create([
    \   '%{WebDevIconsGetFileTypeSymbol()} ',
    \   '%{resolve(expand("%"))}',
    \ ])
    let g:airline_section_c = airline#section#create([
    \   airline#parts#ffenc() !=? '''
    \     ? '%{WebDevIconsGetFileFormatSymbol()." ".&fenc}'
    \     : ''',
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
    let g:airline#extensions#whitespace#symbol = '''
    let g:better_whitespace_enabled = 0
    let g:strip_whitespace_on_save = 1
    let g:strip_whitespace_confirm = 0
    let g:strip_whitelines_at_eof = 1
  ]]

  -- Prose
  vim.cmd [[
    let g:pencil#autoformat = 1
    let g:pencil#cursorwrap = 1
    let g:pencil#wrapModeDefault = 'hard'
    let g:pencil#textwidth = 120
    let g:pencil#conceallevel = 3
    let g:pencil#mode_indicators = {
    \   'hard': '/H',
    \   'auto': '/A',
    \   'soft': '/S',
    \   'off': ''',
    \ }
    let g:limelight_conceal_ctermfg = 240
    let g:limelight_default_coefficient = 0.3
    let g:limelight_priority = -1
    ${lib.optionalString (features.coc && (self.lib.isSupported languagetool pkgs.system)) ''
      let g:languagetool_jar = '${languagetool}/share/languagetool-commandline.jar'
    ''}

    autocmd FileType markdown,text call pencil#init() | Limelight
  ]]

  ${lib.optionalString features.nerdtree ''
    -- NERD tree
    vim.cmd [[
      let g:NERDTreeCaseSensitiveSort = 0
      let g:NERDTreeNaturalSort = 1
      let g:NERDTreeShowHidden = 1
      let g:NERDTreeStatusline = ""
      let g:NERDTreeMinimalUI = 1
      let g:NERDTreeMinimalMenu = 1
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
  ''}

  ${lib.optionalString features.startify ''
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
  ''}

  -- Startup
  vim.cmd [[
    autocmd StdinReadPre * let s:std_in = 1
    ${lib.optionalString (features.nerdtree || features.startify) ''
      autocmd VimEnter * if !exists('s:std_in') && argc() > 0 && isdirectory(argv()[0]) |
      \ enew | endif
    ''}
    ${lib.optionalString features.nerdtree ''
      autocmd VimEnter * if !exists('s:std_in') |
      \ NERDTree | wincmd p | endif
    ''}
    ${lib.optionalString features.startify ''
      autocmd VimEnter * if !exists('s:std_in') && (argc() == 0 || isdirectory(argv()[0])) |
      \ Startify | endif
    ''}
  ]]

  ${lib.optionalString features.coc ''
    -- LaTeX
    vim.cmd [[
      let g:livepreview_previewer = 'mupdf'
      let g:livepreview_engine = 'lualatex'
    ]]
  ''}

  -- Keymaps
  vim.cmd [[
    nnoremap q <Nop>
  ]]
''
