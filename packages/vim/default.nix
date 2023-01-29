{ nixpkgs, system, ... } @ args:
with nixpkgs.legacyPackages.${system}; neovim.override {
  viAlias = true;
  vimAlias = true;
  configure = {
    packages.default = with vimPlugins; {
      start = [
        gitsigns-nvim
        jellybeans-vim
        unite-vim
        vim-airline
        vim-airline-themes
        vim-fugitive
        vim-nix
        vim-startify

        (vimUtils.buildVimPlugin { name = "config"; src = ./config; })
      ];
    };
    customRC = "lua require('config')";
  };
}
