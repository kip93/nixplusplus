{ pkgs, ... } @ args:
{ ... } @ features':
with pkgs;
let
  _optional = condition: value: if condition then value else null;

  features = features' // {
    coc' = features.bash ||
      features.css ||
      features.docker ||
      features.golang ||
      features.html ||
      features.json ||
      features.latex ||
      features.lua ||
      features.markdown ||
      features.python ||
      features.rust ||
      features.snippets ||
      features.toml ||
      features.vimscript ||
      features.yaml;
    python' =
      features.latex;
  };

  nvim = neovim.override {
    viAlias = true;
    vimAlias = true;

    withPython3 = features.python';
    withNodeJs = features.coc';
    withRuby = false;

    extraPython3Packages = pypkgs: with pypkgs; [ ];
    extraLuaPackages = luapkgs: with luapkgs; [ ];
    extraMakeWrapperArgs = ''--prefix PATH : "${lib.makeBinPath (builtins.filter (p: p != null) [
      (_optional features.coc' bat)
      (_optional features.coc' fzf)

      (_optional features.bash shellcheck)
      (_optional features.golang go)
      (_optional features.prose languagetool)
      (_optional features.latex texlab)
      (_optional features.latex zathura)
      (_optional features.lua lua-language-server)
      (_optional features.nix rnix-lsp)
      (_optional features.python (runCommand "coc-python" { } ''
        mkdir -p $out/bin ; ln -sf ${python3.withPackages (pypkgs: with pypkgs; [
          black
          flake8
        ])}/bin/python3 $out/bin/coc-python
      ''))
      (_optional features.rust rust-analyzer)
    ])}"'';

    configure = {
      packages.default = with vimPlugins; with callPackage ./plugins.nix { }; {
        start =
          builtins.filter (p: p != null)
            [
              # Theme
              jellybeans-vim
              (_optional features.nerdtree nerdtree)
              (_optional features.nerdtree nerdtree-syntax-highlight)
              nvim-transparent
              vim-airline
              vim-airline-themes
              vim-devicons
              (_optional features.startify vim-startify)
              virt-column-nvim

              # General
              (_optional features.coc' coc-nvim)
              (_optional features.coc' coc-fzf)
              (_optional features.coc' coc-yank)
              fzf-vim
              undotree
              unite-vim
              vim-better-whitespace
              vim-visual-multi

              # Git
              gitsigns-nvim
              gv-vim
              (_optional features.nerdtree nerdtree-git-plugin)
              vim-fugitive

              # Snippets
              (_optional features.snippets coc-snippets)

              # Prose
              (_optional features.prose limelight-vim)
              (_optional features.prose thesaurus_query-vim)
              (_optional features.prose vim-LanguageTool)
              (_optional features.prose vim-abolish)
              (_optional features.prose vim-pencil)

              # Bash
              (_optional features.bash coc-sh)

              # CSS
              (_optional features.css coc-css)
              (_optional features.css vim-css-color)

              # Docker
              (_optional features.docker coc-docker)

              # GO
              (_optional features.golang coc-go)

              # HTML
              (_optional features.html coc-html)

              # JSON
              (_optional features.json coc-json)

              # LaTeX
              (_optional features.latex coc-texlab)
              (_optional features.latex vim-latex-live-preview)
              (_optional features.latex vimtex)

              # Lua
              (_optional features.lua coc-sumneko-lua)

              # Markdown
              (_optional features.markdown coc-markdownlint)

              # Nix
              (_optional features.nix vim-nix)

              # Python
              (_optional features.python coc-pyright)

              # Rust
              (_optional features.rust coc-rust-analyzer)

              # TOML
              (_optional features.toml coc-toml)

              # Vimscript
              (_optional features.vimscript coc-vimlsp)

              # YAML
              (_optional features.yaml coc-yaml)

              # Config
              (vimUtils.buildVimPlugin {
                name = "config";
                src = writeTextDir "lua/config.lua"
                  (import ./config.nix { inherit features pkgs; });
              })
            ];
      };
      customRC = ''
        lua require('config')
        ${lib.optionalString features.coc' "let g:coc_config_home = '${writeTextDir "coc-settings.json"
          (builtins.toJSON (import ./coc-settings.nix { inherit features pkgs; }))
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
    platforms = [ "x86_64-linux" "aarch64-linux" ] ++ (lib.optional (!features.prose) "armv7l-linux");
  };
}
