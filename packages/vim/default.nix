{ nixpkgs, system, ... } @ args:
with nixpkgs.legacyPackages.${system};
(neovim.override {
  viAlias = true;
  vimAlias = true;

  withPython3 = false;
  withNodeJs = false;
  withRuby = false;

  configure = {
    packages.default = with vimPlugins; {
      start = [
        fzf-vim
        gitsigns-nvim
        gv-vim
        jellybeans-vim
        nerdtree
        nerdtree-git-plugin
        (pkgs.vimUtils.buildVimPlugin {
          name = "vim-nerdtree-syntax-highlight";
          src = pkgs.fetchFromGitHub {
            owner = "johnstef99";
            repo = "vim-nerdtree-syntax-highlight";
            rev = "0c495b4ec3776946d4b6a9f08c0e48d683af4add";
            sha256 = "aH3fdAQQjLVth0rYGnqGIGxRZgSPkmpeUfAwVg8feWY=";
          };
        })
        unite-vim
        vim-airline
        vim-airline-themes
        vim-better-whitespace
        vim-devicons
        vim-fugitive
        vim-nix
        vim-startify
        vim-visual-multi
        (pkgs.vimUtils.buildVimPlugin {
          name = "virt-column-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "lukas-reineke";
            repo = "virt-column.nvim";
            rev = "refs/tags/v1.5.5";
            sha256 = "6EbEzg2bfoHmVZyggwvsDlW9OOA4UkcfO0qG0TEDKQs=";
          };
        })

        (vimUtils.buildVimPlugin { name = "config"; src = ./config; })
      ];
    };
    customRC = "lua require('config')";
  };
}).overrideAttrs (super: {
  name = "neovim-nix++";
  meta = lib.recursiveUpdate super.meta {
    description = "Neovim, with some pizzazz!";
    longDescription = null;
    mainProgram = "nvim";
  };
})
