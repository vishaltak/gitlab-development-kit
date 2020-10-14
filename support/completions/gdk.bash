_gdk_root()
{
  local root
  root=$(realpath .)

  while [ "$root" != "/" ]; do
    if [ -e "$root/GDK_ROOT" ]; then
      echo "$root"
      return
    fi

    root=$(dirname "$root")
  done
}

_gdk()
{
  local index cur root words
  local j k

  index="$COMP_CWORD"
  cur="${COMP_WORDS[index]}"
  root=$(_gdk_root)

  if [ -z "$root" ]; then
    words="$(compgen -W "help version init trust" -- "$cur")"
  else
    case $index in
      1)
        words=$(awk '/^  gdk / { print $2 }' "$root/HELP")
        ;;
      *)
        case "${COMP_WORDS[1]}" in
          start|stop|status|restart|tail)
            words=$(awk -F: '/^[^#:]+:/ { print $1 }' "$root/Procfile")
            ;;
          init|trust)
            compopt -o nospace
            words=$(compgen -o dirnames -- "$cur")
            ;;
          psql)
            if [ "$index" = 2 ]; then
              words="-d"
            elif [ "$index" = 3 ]; then
              words="gitlabhq_development gitlabhq_test"
            fi
            ;;
        esac
        ;;
    esac
  fi
  for j in $(compgen -W "$words" -- "$cur")
  do
    COMPREPLY[k++]=$j
  done
}

complete -F _gdk gdk
