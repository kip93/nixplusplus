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
