#!/usr/bin/env bash

readonly FILE=$1; shift
readonly FILE_BUILT=${FILE/.pu/.png}

readonly WATCH_DIR=watch
readonly WATCH_FILE="${WATCH_DIR}/${FILE_BUILT}"

# messages
_write_watching_file () {
  echo -e -n "\e[0K\r\e[4mwatching file: \"${FILE}\e[0m\"" > /dev/tty
}

_write_bulding () {
  echo -e -n '\e[0K\r  building ...                        ' > /dev/tty
  pid=$!

  spin='-\|/'
  
  i=0

  while kill -0 $pid 2>/dev/null

  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}" > /dev/tty
    sleep .1
  done
}

_write_done () {
  local checkmark="\033[0;32m\xE2\x9C\x94\033[0m"
  echo -e -n "\e[0K\r${checkmark} done!                  " > /dev/tty
}

_write_watch_messages () {
  $(_write_bulding)
  $(_write_done)

  sleep 2
  $(_write_watching_file)
}


# checks and maybe creates WATCH folder
test ! -d $WATCH_DIR \
  && mkdir $WATCH_DIR


# runs first uml build
_build_uml () {
  plantuml $FILE

  mv $FILE_BUILT $WATCH_FILE
}

$(_build_uml)


# watchs, checks diff and maybe runs uml build
_get_file_diff () {
  git diff -U0 $FILE
}

_watch_file_changes () {
  local diff=$(_get_file_diff)
  local last_diff=$(_get_file_diff)

  local is_building=0

  while sleep 2; do
    diff=$(_get_file_diff)

    [ "$last_diff" != "$diff" ] && {
      [ $is_building -eq 1 ] && {
        continue
      }

      isBuilding=1

      $(_build_uml) &

      $(_write_watch_messages) &

      is_building=0
    }

    last_diff=$diff
  done
}

$(_watch_file_changes) &


# watchs image using feh
_open_image () {
  $(_write_watching_file)
  feh --reload 3 $WATCH_FILE > /dev/null 2>&1
}

$(_open_image)


# kills all background process on exit
_kill_back_processes () {
  trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
}

$(_kill_back_processes)
