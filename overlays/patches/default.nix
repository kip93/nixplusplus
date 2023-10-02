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

{ self, ... } @ _inputs:
final: prev: with final; {
  testers = prev.testers // {
    runNixOSTest = args:
      let test = prev.testers.runNixOSTest args; in test // {
        meta = (test.meta or { }) // {
          # NixOS test are Linux exclusive (nixpkgs#193336)
          platforms = test.meta.platforms or self.lib.supportedSystems'.linux;
        };
      };
  };

  jre_headless = prev.jre_headless.overrideAttrs (
    { configureFlags ? [ ]
    , meta ? { platforms = self.lib.supportedSystems; }
    , nativeBuildInputs ? [ ]
    , ...
    }: {
      # Fix cross compilation.
      nativeBuildInputs = nativeBuildInputs ++
        (with buildPackages; [ autoconf stdenv.cc which zip ])
      ;
      configureFlags = configureFlags ++
        (lib.optionals (buildPlatform != targetPlatform) [
          "--with-boot-jdk=${buildPackages.jre_headless.home}"
          "--with-build-jdk=${buildPackages.jre_headless.home}"
        ])
      ;
      # Disable on i686 machines.
      meta = meta // {
        platforms = lib.optionals
          (!lib.hasPrefix "i686-" buildPackages.system)
          (builtins.filter
            (x: !lib.hasPrefix "i686-" x)
            meta.platforms
          )
        ;
      };
    }
  );
  # Apply jre fixes to LanguageTool.
  languagetool = (prev.languagetool.override {
    jre = jre_headless;
  }).overrideAttrs (
    { meta ? { platforms = self.lib.supportedSystems; }
    , ...
    }: {
      meta = meta // {
        platforms = lib.intersectLists
          meta.platforms
          jre_headless.meta.platforms
        ;
      };
    }
  );

  vimPlugins = prev.vimPlugins // {
    # Apply LanguageTool fixes to vim plugin.
    vim-LanguageTool = prev.vimPlugins.vim-LanguageTool.overrideAttrs (
      { meta ? { platforms = self.lib.supportedSystems; }
      , ...
      }: {
        meta = meta // {
          platforms = lib.intersectLists
            meta.platforms
            languagetool.meta.platforms
          ;
        };
      }
    );
  };
}
