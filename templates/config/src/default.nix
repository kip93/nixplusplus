let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes) flake-compat;

  url = "https://github.com/edolstra/flake-compat/archive/${flake-compat.locked.rev}.tar.gz";
  sha256 = flake-compat.locked.narHash;

  flake = (import (fetchTarball { inherit url sha256; }) { src = ./.; }).defaultNix;

in
flake.packages.${builtins.currentSystem}.default
