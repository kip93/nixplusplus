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
with pkgs;
{
  # Lua
  sumneko-lua.serverDir = lua-language-server;
  Lua.telemetry.enable = false;
  # Nix
  languageserver.nix = {
    command = "rnix-lsp";
    filetypes = [ "nix" ];
  };
  # Python
  python = {
    pythonPath = "coc-python";
    formatting.provider = "black";
    linting.flake8Enabled = true;
  };
  pyright.organizeimports.provider = "pyright";
  # Snippets
  snippets = {
    ultisnips.pythonPrompt = false;
    userSnippetsDirectory = ./snippets;
  };
  # Others
  yank.list.maxsize = 100;
} // (pkgs.lib.optionalAttrs (self.lib.isSupported rustc pkgs.system) {
  # Rust
  rust-analyzer.server.path = "${rust-analyzer}/bin/rust-analyzer";
})
