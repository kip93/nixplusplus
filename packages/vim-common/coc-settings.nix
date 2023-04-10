{ features, pkgs, ... }:
with pkgs;
(lib.optionalAttrs features.lua {
  # Lua
  sumneko-lua.serverDir = lua-language-server;
  Lua.telemetry.enable = false;
}) // (lib.optionalAttrs features.nix {
  # Nix
  languageserver.nix = {
    command = "rnix-lsp";
    filetypes = [ "nix" ];
  };
}) // (lib.optionalAttrs features.python {
  # Python
  python = {
    pythonPath = "coc-python";
    formatting.provider = "black";
    linting.flake8Enabled = true;
  };
  pyright.organizeimports.provider = "pyright";
}) // (lib.optionalAttrs features.rust {
  # Rust
  rust-analyzer.server.path = "${rust-analyzer}/bin/rust-analyzer";
}) // (lib.optionalAttrs features.snippets {
  # Snippets
  snippets = {
    ultisnips.pythonPrompt = false;
    userSnippetsDirectory = ./snippets;
  };
}) // {
  # Others
  yank.list.maxsize = 100;
}
