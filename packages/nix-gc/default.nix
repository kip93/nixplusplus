{ nixpkgs, system, ... } @ args:
with nixpkgs.legacyPackages.${system}; writeShellApplication {
  name = "nix-gc";
  runtimeInputs = [ bash coreutils findutils gawk gnused nix ];
  text = ''
    # Defaults
    last=5
    days=28
    user="$(bash -c 'set +H;printf "$((!!"$(id -u)"))"')"

    # Functions
    _default_last="$last"
    _default_days="$days"
    show_help() {
      cat <<EOF >&2
    Wrapper script to garbage collect nix paths, removing old GC roots and then
    deleting unused paths.

    $(printf '\e[1m')USAGE:$(printf '\e[0m')
      $(basename "$0") [ -l $(printf '\e[4m')LAST$(printf '\e[0m') ] [ -d $(printf '\e[4m')DAYS$(printf '\e[0m') ] [ -u ]

    $(printf '\e[1m')FLAGS:$(printf '\e[0m')
      -l $(printf '\e[4m')LAST$(printf '\e[0m')
          Keep the last N generations.
          $(printf '\e[3m')Default: $_default_last$(printf '\e[0m')

      -d $(printf '\e[4m')DAYS$(printf '\e[0m')
          Keep generations newer than N days.
          $(printf '\e[3m')Default: $_default_days$(printf '\e[0m')

      -u
          Delete only generations related to the current user, and nothing else.
          $(printf '\e[3m')Ignored unless run by root$(printf '\e[0m')
    EOF
    }

    clean_profile() {
      if [ -e "$1" ] ; then
        nix-env --profile "$1" --list-generations \
        | sed -E '/\(current\)$/d' \
        | head -n "-''${last}" \
        | awk '{ print $1 " " $2 "T" $3 }' \
        | awk -v threshold="''${threshold}" '{ if ( $2 < threshold ) { print $1 } }' \
        | xargs -r nix-env --profile "$1" --delete-generations
      fi
    }

    # Parse args
    while getopts "hl:d:u" opt ; do
      case "''${opt}" in
        l)
          if [[ "''${OPTARG}" =~ ^[0-9]+$ ]] ; then
            last="''${OPTARG}" ;
          else
            show_help ;
            exit 1 ;
          fi ;;

        d)
          if [[ "''${OPTARG}" =~ ^[0-9]+$ ]] ; then
            days="''${OPTARG}" ;
          else
            show_help ;
            exit 1 ;
          fi ;;

        u)
          user=1 ;;

        h)
          show_help ;
          exit 0 ;;

        *)
          show_help ;
          exit 1 ;;
      esac
    done

    if [ "$#" -ge "$OPTIND" ] ; then
      show_help
      exit 1
    fi

    # Cleanup
    if [ "''${user}" -eq 0 ] ; then
      profiles=("/nix/var/nix/profiles"/{default,system,per-user/*/{profile,home-manager}})
    elif [ "$(id -u)" -eq 0 ] ; then
      profiles=("/nix/var/nix/profiles"/{default,per-user/"''${USER}"/{profile,home-manager}})
    else
      profiles=("/nix/var/nix/profiles/per-user/''${USER}"/{profile,home-manager})
    fi

    threshold="$(date '+%Y-%m-%dT%H:%M:%S' -d "now - ''${days} days")"
    for profile in "''${profiles[@]}" ; do
      clean_profile "$profile"
    done

    if [ "''${user}" -eq 0 ] ; then
      rm -rf /nix/var/nix/gcroots/auto/{,.}* 2>/dev/null ||:
      nix-collect-garbage
    fi
  '';
}
