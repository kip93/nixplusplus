# This file is part of Nix++.
# Copyright (C) 2023-2024 Leandro Emmanuel Reina Kiperman.
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
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.05";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    hydra = {
      url = "github:NixOS/hydra/nix-2.22"; # Keep in sync! (See hydra#1182)
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix.follows = "nix";
      };
    };
    nix = {
      url = "github:NixOS/nix/2.22.2";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    agenix = {
      url = "github:ryantm/agenix/0.15.0";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    cachix = {
      url = "github:cachix/cachix";
      inputs = {
        devenv.follows = "devenv";
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    devenv = {
      url = "github:cachix/devenv/main";
      inputs = {
        cachix.follows = "cachix";
        flake-compat.follows = "flake-compat";
        nix.follows = "nix";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    flake-compat = {
      url = "github:nix-community/flake-compat/master";
    };
    flake-utils = {
      url = "github:numtide/flake-utils/main";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts/main";
      inputs = {
        nixpkgs-lib.follows = "nixpkgs";
      };
    };
    flake-schemas = {
      url = "github:DeterminateSystems/flake-schemas/main";
    };
    gitignore-nix = {
      url = "github:hercules-ci/gitignore.nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    impermanence = {
      url = "github:nix-community/impermanence/master";
    };
    nixos-artwork = {
      url = "github:NixOS/nixos-artwork/master";
      flake = false;
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix/master";
      inputs = {
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore-nix";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay/stable";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
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
    schemas = import ./schemas inputs;
    templates = import ./templates inputs;
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org/"
      "https://devenv.cachix.org"
      "https://npp.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "npp.cachix.org-1:L4IIIpXuj6UnPe/bCNsNquzuyHZfi34mYClXv5xZVx8="
    ];
  };
}
