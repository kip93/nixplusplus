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
  description = ''
    Nix++ : An ever-growing opinionated collection of nix goodies, all available
    from a single neat(-ish) flake ❄.
  '';

  inputs = {
    agenix = {
      url = "github:ryantm/agenix/0.14.0";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs = {
        flake-compat.follows = "flake-compat";
        nix.follows = "nix";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    devour = {
      url = "github:srid/devour-flake/v3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        flake.follows = "";
      };
    };
    flake-utils = {
      url = "github:numtide/flake-utils/main";
      inputs = {
        systems.follows = "systems";
      };
    };
    flake-compat = {
      url = "github:nix-community/flake-compat/master";
      flake = false;
    };
    gitignore-nix = {
      url = "github:hercules-ci/gitignore.nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    hydra = {
      url = "github:NixOS/hydra/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # nix.follows = "nix"; # DON'T! See hydra#1182
      };
    };
    impermanence = {
      url = "github:nix-community/impermanence/master";
    };
    # microvm-nix = {
    #   url = "github:astro/microvm.nix/main";
    #   inputs = {
    #     flake-utils.follows = "flake-utils";
    #     nixpkgs.follows = "nixpkgs";
    #   };
    # };
    nix = {
      url = "github:NixOS/nix/latest-release";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixos-artwork = {
      url = "github:NixOS/nixos-artwork/master";
      flake = false;
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix/master";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        gitignore.follows = "gitignore-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay/stable";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
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
    hydraJobs = import ./hydra inputs;
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
      "k93-1:wHbMV55yrJjYJ8HaxUp+WelU79KYJnil+cfSl3dtn24="
    ];
  };
}
