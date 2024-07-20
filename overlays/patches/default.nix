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

{ self, ... } @ _inputs:
final: prev: with final; {
  jre_headless = prev.jre_headless.overrideAttrs (
    { configureFlags ? [ ]
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
