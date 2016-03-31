#!/usr/bin/env bash

#!/bin/bash

coloredEcho () {
    local exp=$1;
    local color=$2;
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo $exp;
    tput sgr0;
}

exit_on_error () {
    if [ ${1} != 0 ]; then
        coloredEcho "${2}" red
        exit ${1}
    fi
}

retry () {
    local RET=0
    local N=1
    local COMMAND=$1
    local MAX=$2
    local DELAY=$3

    while true; do
        ${COMMAND} && RET=$? && break || {
            if [[ ${N} -lt ${MAX} ]]; then
                ((N++))
                RET=$?
                coloredEcho "<<< Command failed. Attempt ${N}/${MAX}" red
                sleep ${DELAY};
            else
                RET=$?
                coloredEcho "<<< The command (${COMMAND}) has failed after ${N} attempts." red
                break
            fi
        }
    done
    return ${RET}
}

confirm () {
    # call with a prompt string or use a default
    read -n 1 -r -p "${1:-Are you sure? [y/N]} " response
    echo    # move to a new line
    case $response in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}
