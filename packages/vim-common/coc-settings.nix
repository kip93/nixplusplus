{ features, pkgs, ... }:
with pkgs;
(lib.optionalAttrs (features.lua) {
  # Lua
  sumneko-lua.serverDir = sumneko-lua-language-server;
  Lua.telemetry.enable = false;
}) // (lib.optionalAttrs (features.nix) {
  # Nix
  languageserver.nix = {
    command = "rnix-lsp";
    filetypes = [ "nix" ];
  };
}) // (lib.optionalAttrs (features.python) {
  # Python
  python.pythonPath = "coc-python";
  python.formatting.provider = "black";
  pyright.organizeimports.provider = "pyright";
  python.linting.flake8Enabled = true;
}) // (lib.optionalAttrs (features.rust) {
  # Rust
  rust-analyzer.server.path = "${rust-analyzer}/bin/rust-analyzer";
}) // (lib.optionalAttrs (features.snippets) {
  # Snippets
  snippets = {
    ultisnips.pythonPrompt = false;
    userSnippetsDirectory = ./snippets;
  };
}) // {
  # Others
  yank.list.maxsize = 100;
}
