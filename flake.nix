{
  description = "Nix++ : A collection of fun nix things.";

  inputs = {
    agenix = {
      url = "git+https://github.com/ryantm/agenix?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "git+https://github.com/nix-community/fenix?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "git+https://github.com/edolstra/flake-compat?ref=master";
      flake = false;
    };
    flake-utils = {
      url = "git+https://github.com/numtide/flake-utils?ref=master";
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
    hydra = {
      url = "git+https://github.com/NixOS/hydra?ref=master";
      inputs.nix.follows = "nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "git+https://github.com/nix-community/impermanence?ref=master";
    };
    microvm-nix = {
      url = "git+https://github.com/astro/microvm.nix?ref=main";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "git+https://github.com/nix-community/naersk?ref=master";
    };
    nix = {
      url = "git+https://github.com/NixOS/nix?ref=latest-release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-serve = {
      url = "git+https://github.com/edolstra/nix-serve?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "git+https://github.com/NixOS/nixos-hardware?ref=master";
    };
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-22.11";
    };
    nixpkgs-fmt = {
      url = "git+https://github.com/nix-community/nixpkgs-fmt?ref=master";
      inputs.flake-utils.follows = "flake-utils";
      inputs.fenix.follows = "fenix";
    };
    nixpkgs-lint = {
      url = "git+https://github.com/nix-community/nixpkgs-lint?ref=master";
      inputs.naersk.follows = "naersk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    nur = {
      url = "git+https://github.com/nix-community/NUR?ref=master";
    };
  };

  outputs = { ... } @ inputs: {
    apps = import ./apps inputs;
    packages = import ./packages inputs;
    lib = import ./lib inputs;
    nixosModules = import ./modules;
    overlays = import ./overlays;
    templates = import ./templates;
  };
}
