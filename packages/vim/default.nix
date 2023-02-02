{ nixpkgs, system, ... } @ args:
with nixpkgs.legacyPackages.${system};
(neovim.override {
  viAlias = true;
  vimAlias = true;

  withPython3 = false;
  withNodeJs = false;
  withRuby = false;

  configure = {
    packages.default = with vimPlugins; with pkgs.callPackage ./plugins.nix { }; {
      start = [
        fzf-vim
        gitsigns-nvim
        gv-vim
        jellybeans-vim
        nerdtree
        nerdtree-git-plugin
        nerdtree-syntax-highlight
        nvim-transparent
        unite-vim
        vim-airline
        vim-airline-themes
        vim-better-whitespace
        vim-devicons
        vim-fugitive
        vim-nix
        vim-startify
        vim-visual-multi
        virt-column-nvim

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
