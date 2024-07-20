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

{ flake-schemas, hydra, nix, ... } @ _inputs:
final: prev:
let
  # A fake set of overlaid pkgs, to ensure that hydra uses it's own version of
  # nix, due to hydra#1182.
  # Also useful for just getting out the relevant parts.
  hydra_prev = prev
    // (hydra.inputs.nix.overlays.default hydra_final prev)
  ;
  hydra_final = hydra_prev
    // (hydra.overlays.default hydra_final hydra_prev)
  ;
  # A fake overlaid pkgs, to just extract the interesting parts out of the
  # nix overlay.
  nix_final = final
    // (nix.overlays.default nix_final prev)
  ;

in
{
  # Expose the relevant packages into the overlay
  inherit (nix_final) nixStable nix-perl-bindings;
  nix = nix_final.nix.override
    {
      boehmgc = nix_final.boehmgc.override {
        enableLargeConfig = true;
      };
    } // {
    perl-bindings = nix_final.nix-perl-bindings;
  };

  nixVersions = with final; prev.nixVersions // {
    schemas = nixSchemas;
  };

  # Build a nix package that has flake schema support (see nix#8892).
  nixSchemas = with final; (callPackage "${fetchFromGitHub {
    owner = "DeterminateSystems";
    repo = "nix-src";
    rev = "flake-schemas";
    hash = "sha256-LcCwNsd1v5HjOlNPxtQHjosomwaktcLUjGDuYlapyLE=";
  }}/package.nix"
    { inherit flake-schemas; }
  ).overrideAttrs (_: {
    pname = "nix-schemas";
    # Schema tests still require internet connection
    doCheck = false;
    doInstallCheck = false;
  });

  hydra_unstable = with final; hydra_final.hydra.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      # See nix#7098.
      (writeText "hydra-disable-restrict-eval.patch" ''
        --- a/src/hydra-eval-jobs/hydra-eval-jobs.cc
        +++ b/src/hydra-eval-jobs/hydra-eval-jobs.cc
        @@ -317,1 +317,1 @@
        -        evalSettings.restrictEval = true;
        +        evalSettings.restrictEval = false;
      '')
      # See cachix/devenv#658.
      (writeText "hydra-disable-pure-eval.patch" ''
        --- a/src/hydra-eval-jobs/hydra-eval-jobs.cc
        +++ b/src/hydra-eval-jobs/hydra-eval-jobs.cc
        @@ -321,1 +321,1 @@
        -        evalSettings.pureEval = pureEval;
        +        evalSettings.pureEval = false;
      '')
    ];
  });
}
