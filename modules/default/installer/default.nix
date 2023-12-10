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

{ ... } @ _inputs:
{
  config.system.systemBuilderCommands = ''
    (set -eu; cat <<EOF | sed -E 's/^ {2}//' >$out/install
      #!$out/sw/bin/sh
      set -eu

      args=()
      profile=/nix/var/nix/profiles/system
      cmd=$out/bin/switch-to-configuration
      while [ "\$#" -gt 0 ] ; do
        i="\$1" ; shift ;
        case "\$i" in
          boot|switch|test|dry-activate)
            args+=("\$i") ; action="\''${action:-}\''${action:+ }\$i" ;
            ;;
          --install-bootloader)
            export NIXOS_INSTALL_BOOTLOADER=1 ;
            ;;
          --profile-name|-p)
            [ -n "\''${1:-}" ] || (printf '%s requires an argument\n' "\$i" ; exit 1) ;
            profile_name="\$1" ; shift ;
            profile="/nix/var/nix/profiles/system-profiles/\$profile_name" ;
            ;;
          --specialisation|-c)
            [ -n "\''${1:-}" ] || (printf '%s requires an argument\n' "\$i" ; exit 1) ;
            specialisation="\$1" ; shift ;
            cmd="$out/specialisation/\$specialisation/bin/switch-to-configuration"
            [ -f "\$cmd" ] || (printf 'Specialisation not found: %s\n' "\$specialisation" ; exit 1)
            ;;
          -*)
            printf 'Unknown option: %s\n' "\$i" ; exit 1 ;
            ;;
          *)
            printf 'Unknown action: %s\n' "\$i" ; exit 1 ;
            ;;
        esac
      done

      case "\''${action:-}" in
        boot|switch)
          mkdir -p -m 0755 "\$(dirname "\$profile")" ;
          nix-env --profile "\$profile" --set $out ;
          ;;
        test|dry-activate)
          ;;
        ''')
          printf 'Missing action\n' ; exit 1 ;
          ;;
        *)
          printf 'Conflicting actions: %s\n' "\$action" ; exit 1 ;
          ;;
      esac

      exec "\$cmd" "\''${args[@]}"
    EOF
    chmod +x $out/install
    )
  '';
}
