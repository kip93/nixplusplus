{ self, localSystem, crossSystem, ... } @ args:
import ../vim-common/setup.nix args {
  bash = true;
  css = true;
  docker = true;
  golang = true;
  html = true;
  json = true;
  latex = true;
  lua = true;
  markdown = true;
  nerdtree = true;
  nix = true;
  prose = true;
  python = true;
  rust = true;
  snippets = true;
  startify = true;
  toml = true;
  vimscript = true;
  yaml = true;
}
