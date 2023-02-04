{ nixpkgs, system, ... } @ args:
with nixpkgs.legacyPackages.${system};
let
  nvim = neovim.override {
    viAlias = true;
    vimAlias = true;

    withPython3 = false;
    withNodeJs = false;
    withRuby = false;

    configure = {
      packages.default = with vimPlugins; with callPackage ./plugins.nix { }; {
        start = [
          # Theme
          jellybeans-vim
          nerdtree
          nerdtree-syntax-highlight
          nvim-transparent
          vim-airline
          vim-airline-themes
          vim-devicons
          vim-startify
          virt-column-nvim

          # General
          fzf-vim
          unite-vim
          vim-better-whitespace
          vim-visual-multi

          # Git
          gitsigns-nvim
          gv-vim
          nerdtree-git-plugin
          vim-fugitive

          # Nix
          vim-nix

          # Config
          (vimUtils.buildVimPlugin {
            name = "config";
            src = runCommand "config" { } ''
              mkdir -p $out/lua
              ln -sf ${./config.lua} $out/lua/config.lua
            '';
          })
        ];
      };
      customRC = "lua require('config')";
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
  };
}
