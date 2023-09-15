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

{ pkgs, ...}: with pkgs; {
  packages = [ cacert git git-lfs ];
  pre-commit.hooks = {
    shellcheck.enable = true;
    check-working-tree = {
      enable = true;
      description = "Run some validations against the files to be commited";
      stages = [ "commit" "merge-commit" ];
      entry = "${writeShellScript "check-working-tree" ''
        # Set search path
        export PATH=${lib.escapeShellArg (lib.makeBinPath [
          bash
          coreutils
          findutils
          gawk
          git
          gnugrep
        ])}

        exec 1>&2 # stdout -> stderr

        # Check for non-ascii file names.
        bad_names() (
          git diff --cached --name-only -z HEAD -- \
          | LC_ALL=C grep -zP '[^\x20-\x7E]'
        )
        if [ "$(bad_names | wc -c)" -ne 0 ] ; then
          printf '\x1B[31mERROR:\x1B[0m Filenames with invalid characters found.\n'
          bad_names \
          | xargs -0 printf ' * %s\n'
          exit 1
        fi

        # Show whitespace errors.
        if ! git diff-index --check --cached HEAD -- >/dev/null ; then
          printf '\x1B[31mERROR:\x1B[0m Found files with whitespace errors.\n'
          git diff-index --cached --name-only -z HEAD -- \
          | while IFS= read -r -d $'\0' f ; do \
            git diff-index --check --cached HEAD -- "$f" >/dev/null \
            || printf '%s\0' "$f" \
          ; done \
          | xargs -0 printf ' * %s\n'
          exit 1
        fi

        # Show outdated license headers.
        current_year="$(date +%Y)" ${/* Get the current year first, in case it's the night of 31st of December. */ ""}
        files_with_outdated_license() (
          git diff --cached --name-only -z HEAD -- ${/* Find staged files with headers. */ ""} \
          | while IFS= read -r -d $'\0' f ; do \
            git show ":$f" \
            | awk -v f="$f" '/\yThis file is part of Nix\+\+\./{printf "%s\0",f}/^\s*$/{next}{exit}' \
          ; done \
          | while IFS= read -r -d $'\0' f ; do ${/* Check their headers' copyright years. */ ""} \
            ( ${/* Parse the copyright years. */ ""} \
              ( ${/* Parse the year ranges. */ ""} \
                git show ":$f" \
                | awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' \
                | grep -zoP '\d+(-\d+)?' \
                | (grep -z -||:) \
                | while IFS= read -r -d $'\0' y ; do \
                  printf "%s\0" $(seq "''${y%-*}" "''${y#*-}") \
                ; done \
              ) ; ( ${/* Get the plain years as-is. */ ""} \
                git show ":$f" \
                | awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' \
                | grep -zoP '\d+(-\d+)?' \
                | (grep -vz -||:) \
              ) \
            ) | sort -nuz \
            | grep -qP "^''${current_year}$" ${/* Check if any of the listed years correspond to the current one. */ ""} \
            || printf '%s\0' "$f" ${/* Print the paths of the files that failed the check. */ ""} \
          ; done
        )
        if [ "$(files_with_outdated_license | wc -c)" -ne 0 ] ; then
          printf '\x1B[31mERROR:\x1B[0m Found files with outdated licenses.\n'
          files_with_outdated_license \
          | xargs -0 printf ' * %s\n'
          exit 1
        fi
      ''}";
    };
    prepare-commit-template = {
      enable = true;
      description = "Add some dynamic info onto the commit message template";
      stages = [ "prepare-commit-msg" ];
      entry = "${writeShellScript "prepare-commit-template" ''
        # Set search path
        export PATH=${lib.escapeShellArg (lib.makeBinPath [
          coreutils
          git
          gnused
        ])}

        exec 1>&2 # stdout -> stderr

        # Remove default help message.
        sed -i '/^# Please enter the commit message for your changes./Q' "$1"

        # Put in custom help message.
        printf '# About to commit the following changes:\n' >>"$1"
        git status --short \
        | sed -nE 's/^(\w)(.)/#   \1/p' >>"$1"
      ''}";
    };
    check-commit-message = {
      enable = true;
      description = "Check that the commit message that was written follows conventions";
      stages = [ "commit-msg" ];
      entry = "${writeShellScript "check-commit-message" ''
        # Set search path
        export PATH=${lib.escapeShellArg (lib.makeBinPath [
          coreutils
          gawk
          gnused
        ])}

        exec 1>&2 # stdout -> stderr

        # Delete irrelevant lines.
        sed -iE -n '/^\s*#/d;p' "$1"
        # shellcheck disable=SC2016
        sed -iE -n '/^\s*$/!{p;b};h;:loop;$b end;n;/^\s*$/b loop;:end;/^\s*$/{p;b};H;x;p' "$1"

        # Check the commit message.
        if [ "$(awk '{printf "%s",$0;exit}' "$1" | wc -c)" -eq 0 ] ; then
          printf '\x1B[31mERROR:\x1B[0m Missing commit message.\n'
          exit 1

        elif [ "$(awk '{printf "%s",$0;exit}' "$1" | wc -c)" -gt 50 ] ; then
          printf '\x1B[31mERROR:\x1B[0m Commit message is over 50 characters.\n'
          exit 1

        elif [ "$(awk 'NR==1{next}length($0)>72{printf "%s",$0}' "$1" | wc -c)" -gt 0 ] ; then
          printf '\x1B[31mERROR:\x1B[0m Found commit description line(s) over 72 characters.\n'
          exit 1
        fi
      ''}";
    };
  };

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

    # Symlink hooks that are not (yet?) supported by devenv
    ln -sfT commit-msg ./.git/hooks/applypatch-msg
    ln -sfT pre-commit ./.git/hooks/pre-applypatch
  '';
}
