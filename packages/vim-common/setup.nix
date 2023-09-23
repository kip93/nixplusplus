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

{ pkgs, self, ... } @ _args:
{ ... } @ features:
with pkgs;
let
  # Not including any compilers, since nix's going to handle that (and this is large enough as it is).
  PATH = builtins.filter (x: self.lib.isSupported x pkgs.system) ([
    # Global
    fzf
    ripgrep
    silver-searcher
    # Git
    cacert
    git
    git-lfs
    openssh
  ] ++ (lib.optionals features.coc ([
    # CoC
    bat
    nodejs
  ] ++ [
    # Bash
    shellcheck
    # Go
    go
    # LaTeX
    mupdf
    texlab
    # Lua
    lua-language-server
    # Nix
    rnix-lsp
    # Prose
    languagetool
    # Python
    (runCommand "coc-python" { } ''
      mkdir -p $out/bin ; ln -sf ${python3.withPackages (pypkgs: with pypkgs; [
        black
        flake8
      ])}/bin/python3 $out/bin/coc-python
    '')
    # Rust
    rust-analyzer
  ])));

  PLUGINS = builtins.filter (x: self.lib.isSupported x pkgs.system) (with vimPlugins; [
    # Theme
    jellybeans-vim
    nvim-transparent
    vim-airline
    vim-airline-themes
    vim-devicons
    virt-column-nvim
    # General
    fzf-vim
    undotree
    unite-vim
    vim-better-whitespace
    vim-visual-multi
    # Git
    gitsigns-nvim
    gv-vim
    vim-fugitive
    # CSS
    vim-css-color
    # LaTeX
    vimtex
    # Nix
    vim-nix
    # Prose
    limelight-vim
    thesaurus_query-vim
    vim-abolish
    vim-pencil
  ] ++ (lib.optionals features.nerdtree [
    # File tree
    nerdtree
    nerdtree-git-plugin
    nerdtree-syntax-highlight
  ]) ++ (lib.optionals features.startify [
    # Start page
    vim-startify
  ]) ++ (lib.optionals features.coc [
    # CoC
    coc-nvim
    coc-fzf
    coc-snippets
    coc-yank
    # Bash
    coc-sh
    # CSS
    coc-css
    # Docker
    coc-docker
    # GO
    coc-go
    # HTML
    coc-html
    # JSON
    coc-json
    # LaTeX
    coc-texlab
    vim-latex-live-preview
    # Lua
    coc-sumneko-lua
    # Markdown
    coc-markdownlint
    # Prose
    vim-LanguageTool
    # Python
    coc-pyright
    # Rust
    coc-rust-analyzer
    # TOML
    coc-toml
    # Vimscript
    coc-vimlsp
    # YAML
    coc-yaml
  ]));

  nvim = neovim.override {
    viAlias = true;
    vimAlias = true;

    withPython3 = true;
    withNodeJs = features.coc;
    withRuby = false;

    extraPython3Packages = pypkgs: with pypkgs; [ ];
    extraLuaPackages = luapkgs: with luapkgs; [ ];
    extraMakeWrapperArgs = "--prefix PATH : ${lib.escapeShellArg (lib.makeBinPath PATH)}";

    configure = {
      packages.default = {
        start = PLUGINS ++ [
          (vimUtils.buildVimPlugin {
            name = "config";
            src = writeTextDir "lua/config.lua"
              (import ./config.nix { inherit features pkgs self; });
          })
        ];
      };
      customRC = ''
        lua require('config')
        ${lib.optionalString features.coc "let g:coc_config_home = '${writeText "coc-settings.json"
          (builtins.toJSON (import ./coc-settings.nix { inherit features pkgs self; }))
        }'"}
      '';
    };
  };

in
symlinkJoin rec {
  name = "neovim-nix++";
  paths = [
    nvim
    (runCommand "nvim-symlink" { }
      "mkdir -p $out/bin ; ln -sf ${nvim}/bin/nvim $out/bin/v"
    )
  ];

  meta = nvim.meta // {
    inherit name;
    description = "Neovim, with some pizzazz!";
    longDescription = null;
    mainProgram = "v";
    platforms = lib.optionals (!lib.hasPrefix "armv6l-" buildPlatform.system)
      nvim.meta.platforms
    ;
  };
}
