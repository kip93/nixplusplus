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
      url = "git+https://github.com/ryantm/agenix?ref=main";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "git+https://github.com/numtide/flake-utils?ref=main";
    };
    gitignore-nix = {
      url = "git+https://github.com/hercules-ci/gitignore.nix?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?ref=release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    # hydra = {
    #   url = "git+https://github.com/NixOS/hydra?ref=master";
    #   inputs.nix.follows = "nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # impermanence = {
    #   url = "git+https://github.com/nix-community/impermanence?ref=master";
    # };
    # microvm-nix = {
    #   url = "git+https://github.com/astro/microvm.nix?ref=main";
    #   inputs.flake-utils.follows = "flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nix = {
    #   url = "git+https://github.com/NixOS/nix?ref=latest-release";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nixos-artwork = {
      url = "git+https://github.com/NixOS/nixos-artwork?ref=master";
      flake = false;
    };
    nixos-hardware = {
      url = "git+https://github.com/NixOS/nixos-hardware?ref=master";
    };
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable"; # TODO: nixos-23.05
    };
    # nur = {
    #   url = "git+https://github.com/nix-community/NUR?ref=master";
    # };
    rust-overlay = {
      url = "git+https://github.com/oxalica/rust-overlay?ref=master";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { ... } @ inputs: {
    apps = import ./apps inputs;
    checks = import ./checks inputs;
    lib = import ./lib inputs;
    nixosModules = import ./modules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
    templates = import ./templates inputs;
  };
}
