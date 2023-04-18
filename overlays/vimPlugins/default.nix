{ nixpkgs, self, ... } @ inputs:
final: prev: with final; {
  vimPlugins = prev.vimPlugins // builtins.listToAttrs (builtins.map
    (pluginConfig: {
      inherit (pluginConfig) name;
      value = vimUtils.buildVimPlugin pluginConfig;
    })
    [
      {
        name = "nvim-transparent";
        src = fetchFromGitHub {
          owner = "xiyaowong";
          repo = "nvim-transparent";
          rev = "6816751e3d595b3209aa475a83b6fbaa3a5ccc98";
          sha256 = "j1PO0r2q5w0fJvO7BG0xXDjIdOVl73eGO1rclB221uw=";
        };
      }
      {
        name = "nerdtree-syntax-highlight";
        src = fetchFromGitHub {
          owner = "johnstef99";
          repo = "vim-nerdtree-syntax-highlight";
          rev = "0c495b4ec3776946d4b6a9f08c0e48d683af4add";
          sha256 = "aH3fdAQQjLVth0rYGnqGIGxRZgSPkmpeUfAwVg8feWY=";
        };
      }
      {
        name = "virt-column-nvim";
        src = fetchFromGitHub {
          owner = "lukas-reineke";
          repo = "virt-column.nvim";
          rev = "refs/tags/v1.5.5";
          sha256 = "6EbEzg2bfoHmVZyggwvsDlW9OOA4UkcfO0qG0TEDKQs=";
        };
      }
    ]
  );
}
