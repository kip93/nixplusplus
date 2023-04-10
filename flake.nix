{
  description = "Nix++ : A collection of fun nix things.";

  inputs = {
    agenix = {
      url = "git+https://github.com/ryantm/agenix?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # flake-compat = {
    #   url = "git+https://github.com/edolstra/flake-compat?ref=master";
    #   flake = false;
    # };
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
    #   url = "git+https://github.com/NixOS/nix?ref=latest-release"; # TODO: 2.13?
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nixos-hardware = {
      url = "git+https://github.com/NixOS/nixos-hardware?ref=master";
    };
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable"; # TODO: nixos-23.05
    };
    # nur = {
    #   url = "git+https://github.com/nix-community/NUR?ref=master";
    # };
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
