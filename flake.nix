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

{
  description = "Nix++ : A collection of fun nix things.";

  inputs = {
    agenix = {
      url = "git+https://github.com/ryantm/agenix?ref=refs/tags/0.14.0";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "git+https://github.com/cachix/devenv?ref=refs/tags/latest";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nix.follows = "nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };
    devour = {
      url = "git+https://github.com/srid/devour-flake?ref=refs/tags/v3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.flake.follows = "";
    };
    flake-utils = {
      url = "git+https://github.com/numtide/flake-utils?ref=main";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "git+https://github.com/edolstra/flake-compat?ref=master";
      flake = false;
    };
    gitignore-nix = {
      url = "git+https://github.com/hercules-ci/gitignore.nix?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?ref=release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "git+https://github.com/nix-community/impermanence?ref=master";
    };
    # microvm-nix = {
    #   url = "git+https://github.com/astro/microvm.nix?ref=main";
    #   inputs.flake-utils.follows = "flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nix = {
      url = "git+https://github.com/NixOS/nix?ref=latest-release";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-artwork = {
      url = "git+https://github.com/NixOS/nixos-artwork?ref=master";
      flake = false;
    };
    nixos-hardware = {
      url = "git+https://github.com/NixOS/nixos-hardware?ref=master";
    };
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-23.05";
    };
    pre-commit-hooks = {
      url = "git+https://github.com/cachix/pre-commit-hooks.nix?ref=master";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.gitignore.follows = "gitignore-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "git+https://github.com/oxalica/rust-overlay?ref=stable";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems = {
      url = "path:systems.nix";
      flake = false;
    };
  };

  outputs = { ... } @ inputs: {
    apps = import ./apps inputs;
    devShells = import ./shells inputs;
    checks = import ./checks inputs;
    lib = import ./lib inputs;
    nixosModules = import ./modules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
    templates = import ./templates inputs;
  };

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://kip93.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "kip93.cachix.org-1:SSwmPNc/WrxSIMKREDw/cisT17XYLB14sEkx1HMXGwQ="
    ];
  };
}
