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

{ pkgs, ... }:
with pkgs; {
  enterShell = ''
    # Set git configs
    git config --local --replace-all commit.cleanup strip
    git config --local --replace-all commit.status true
    git config --local --replace-all commit.verbose true
    git config --local --replace-all core.autocrlf input
    git config --local --replace-all checkout.defaultRemote origin
    git config --local --replace-all merge.ff only
    git config --local --replace-all pull.ff only
    git config --local --replace-all pull.rebase true
    git config --local --replace-all push.autoSetupRemote true
    git config --local --replace-all push.default current
    git config --local --replace-all push.useForceIfIncludes true
    git config --local --replace-all commit.template ${writeText "git_commit-template" ''
      ${/* Intentional blank line: */ ""}
      # Limits:                                        ↑                     ↓
      # A longer explanation of the commit. E.g.,
      #  * What is being fixed/added?
      #  * Why is this needed?
      #  * How was this accomplished?
      #  * When did the problem first arise?
      #  * Where is the issue being tracked?
    ''}

    # Add extra remotes
    git remote rm upstream 2>/dev/null||:; git remote add upstream 'ssh://git.kip93.net/nix++'
    git remote rm gitlab   2>/dev/null||:; git remote add gitlab   'git@gitlab.com:kip93/nixplusplus.git'
    git remote rm github   2>/dev/null||:; git remote add github   'git@github.com:kip93/nixplusplus.git'
  '';
}
