{ self, system, ... } @ args:
import ../vim-common/setup.nix args {
  bash = false;
  css = false;
  docker = false;
  golang = false;
  html = false;
  json = false;
  latex = false;
  lua = false;
  markdown = false;
  nerdtree = true;
  nix = false;
  prose = false;
  python = false;
  rust = false;
  snippets = false;
  startify = true;
  toml = false;
  vimscript = false;
  yaml = false;
}
