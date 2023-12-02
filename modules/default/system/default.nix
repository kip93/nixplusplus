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

{ nixpkgs, self, ... } @ _inputs:
{ config, lib, ... }: {
  config = {
    nixpkgs.overlays = [ self.overlays.default ];
    nix = {
      settings = {
        allowed-users = [ "*" ];
        trusted-users = [ "root" "@wheel" ];

        sandbox = true;
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        experimental-features = [ "nix-command" "flakes" ];

        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org/"
          "https://npp.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "npp.cachix.org-1:L4IIIpXuj6UnPe/bCNsNquzuyHZfi34mYClXv5xZVx8="
        ];
      };
      registry = builtins.mapAttrs
        (_: flake: { inherit flake; })
        self.lib.flakes.registry
      ;

      nixPath = [ "nixpkgs=/run/flakes/nixpkgs" ];
    };

    systemd.tmpfiles.rules = [
      "d /run/flakes 0755 0 0 0 -"
    ] ++ (builtins.map
      (name: "L+ /run/flakes/${name} - - - - ${self.lib.flakes.registry.${name}}")
      (builtins.attrNames self.lib.flakes.registry)
    );

    system.nixos = {
      version = with config.system.nixos; "${release}.${versionSuffix}";
      versionSuffix = "${
        nixpkgs.shortRev or nixpkgs.dirtyShortRev or "dirty"
      }.${
        self.shortRev or self.dirtyShortRev or "dirty"
      }${
        let rev = config.system.configurationRevision; in
        lib.optionalString (toString rev != "") ".${rev}"
      }";
      tags = [ "npp" ];
    };
  };
}
