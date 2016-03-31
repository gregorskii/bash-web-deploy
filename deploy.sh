#!/bin/sh

source ./functions.sh

REMOTE_JENKINS_SERVER_NAME=""
SWAP_FOLDER=deployswap
DEPLOY_USER=deployuser

##
# Script should not exit when sourced
##
if [ "$0" = "$BASH_SOURCE" ]; then
    SD_SOURCED=0
else
    SD_SOURCED=1
fi

# --------------------------------------------------------- #
# deploy_site ()                                            #
# Deploys the site to the current hosts manifest            #
# Parameters:                                               #
# $DEPLOY_DIR  - path to swap files                         #
# $BRANCH  - branch to pull                                 #
# $FRESH - whether to remove /build/branch folder           #
# before running                                            #
# Returns: 0 on success, NZ Error Code on error             #
# --------------------------------------------------------- #
deploy_site() {

    source ./deploy-functions.sh

    local BASE=$(pwd)

    local DEPLOY_DIR=$1
    local BRANCH=$2
    local FRESH=$3

    local HOSTS_FILE="./hosts.txt"
    local WEBROOT=/var/www
    local REPO_URL=<GIT REPO>

    local BRANCH_DIR=${DEPLOY_DIR}/${SWAP_FOLDER}/builds/$(echo ${BRANCH} | tr / _)

    pull_site "${REPO_URL}" "${BRANCH}" "${BRANCH_DIR}" "${FRESH}"

    cd "${BRANCH_DIR}"

    ## Get the git hash to use as the folder on remote
    HASH=$(git rev-parse --short HEAD)
    coloredEcho ">>> ($BASH_SOURCE) Most recent commit hash: ${HASH}" magenta

    build_site

    rc=$?
    if [[ ${rc} != 0 ]] ; then
        coloredEcho "<<< ($BASH_SOURCE) Gulp build did not complete" red
        if [ ${SD_SOURCED} -eq 1 ]; then
            return ${rc}
        else
            exit ${rc}
        fi
    else
        coloredEcho ">>> ($BASH_SOURCE) Gulp Build complete" magenta
    fi

    cd "${BASE}"

    while read SERVER; do
        local PUBLIC_IP=$(echo ${SERVER} | awk '{print $1}')
        local PUBLIC_DNS=$(echo ${SERVER} | awk '{print $2}')

        local REMOTE=${DEPLOY_USER}@${PUBLIC_IP}:${WEBROOT}/${PUBLIC_DNS}/builds/${HASH}/

        coloredEcho "Deploying to: ${REMOTE}"

        rsync -Cr \
            --include-from="./deploy-includes.txt" \
            --exclude="*" \
            -e ssh -C ${BRANCH_DIR} ${REMOTE}

        rc=$?
        if [[ ${rc} != 0 ]] ; then
            coloredEcho "<<< ($BASH_SOURCE) Rsync did not complete" red
            if [ ${SD_SOURCED} -eq 1 ]; then
                return ${rc}
            else
                exit ${rc}
            fi
        else
            coloredEcho ">>> ($BASH_SOURCE) Rsync files complete" magenta
        fi

        coloredEcho ">>> ($BASH_SOURCE) Running cleanup tasks on remote" green
        ssh -t -t ${DEPLOY_USER}@${PUBLIC_IP} \
        "HASH=$HASH
        rm webroot
        ln -s ./builds/$HASH ./webroot
        cd ./webroot
        composer dump-autoload
        php artisan --env=stage dump-autoload
        php artisan --env=stage clear-compiled
        "

    done < ${HOSTS_FILE}

    coloredEcho ">>> ($BASH_SOURCE) Deploy Complete" yellow

    if [ ${SD_SOURCED} -eq 1 ]; then
        return 0
    fi
}

if [ ${SD_SOURCED} -ne 1 ]; then

    # Specify where you want this script doing its work
    if [ $HOSTNAME = '${REMOTE_JENKINS_SERVER_NAME}' ];
        then
            DEPLOY_DIR=$WORKSPACE
    else
        DEPLOY_DIR=~/Downloads
    fi

    FRESH=false

    BAD_PARAM_ERROR="Invalid arguments: usage $BASH_SOURCE \n
        --branch=[develop|master|feature/someFeature] \n
        --fresh=[true|false] (defaults to false)"

    if [ "$1" == "" ] || [ "$2" == "" ]; then
        coloredEcho "${BAD_PARAM_ERROR}" red
        if [ ${SD_SOURCED} -eq 1 ]; then
            return 1
        else
            exit 1
        fi
    fi

    while [ $# -gt 0 ]; do
      case "$1" in
        --branch=*)
          BRANCH="${1#*=}"
          ;;
        --fresh=*)
          FRESH="${1#*=}"
          ;;
        *)
            coloredEcho "${BAD_PARAM_ERROR}" red
            if [ ${SD_SOURCED} -eq 1 ]; then
                return 1
            else
                exit 1
            fi
      esac
      shift
    done

    if [ ${SD_SOURCED} -ne 1 ]; then
        confirm || exit
    fi

    deploy_site "${DEPLOY_DIR}" "${BRANCH}" "${FRESH}"
fi
