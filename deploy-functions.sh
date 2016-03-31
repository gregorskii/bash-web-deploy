#!/usr/bin/env bash

# http://stackoverflow.com/questions/12451278/bash-capture-stdout-to-a-variable-but-still-display-it-in-the-console
exec 5>&1

# --------------------------------------------------------- #
# pull_site ()                                              #
# Pulls the site code from GIT                              #
# Runs package managers                                     #
# Parameters:                                               #
# $REPO_URL - repo to get it from                           #
# $BRANCH  - branch to pull                                 #
# $FRESH - whether to remove /build/branch folder           #
# before running                                            #
# Returns: 0 on success, NZ Error Code on error             #
# --------------------------------------------------------- #
pull_site() {

    REPO_URL=$1
    BRANCH=$2
    BRANCH_DIR=$3
    FRESH=$4

    ## Ensure branch folder exists
    if [ "${FRESH}" == "true" ]; then rm -rf ${BRANCH_DIR}; fi
    if [ ! -d "${BRANCH_DIR}" ]; then mkdir -p ${BRANCH_DIR}; fi

    ## Git pull or clone
    if [ ! -d "${BRANCH_DIR}/.git" ]; then
        git clone -b ${BRANCH} ${REPO_URL} ${BRANCH_DIR}
        cd "${BRANCH_DIR}"
    else
        cd "${BRANCH_DIR}"
        RESULT=$(git pull | tee /dev/fd/5)

        rc=$?
        if [ ${rc} != 0 ]; then
            coloredEcho "<<< ($BASH_SOURCE) Git Pull Failed" red
            return ${rc}
        fi

        # Check for changes to deps
        if [[ ${RESULT} == *"bower.json"* ]]; then rm -rf ./bower_components; fi
        if [[ ${RESULT} == *"package.json"* ]]; then rm -rf ./node_modules; fi
        if [[ ${RESULT} == *"composer.json"* ]]; then composer update; fi
    fi

    # Install node deps if missing
    if [ -f './package.json' ] && [ ! -d './node_modules' ]; then
        npm i

        rc=$?
        if [ ${rc} != 0 ]; then
            coloredEcho "<<< ($BASH_SOURCE) Node modules install failed" red
            return ${rc}
        fi
    fi

    # Install bower deps if missing
    if [ -f './bower.json' ] && [ ! -d './bower_components' ]; then
        bower install

        rc=$?
        if [ ${rc} != 0 ]; then
            coloredEcho "<<< ($BASH_SOURCE) Bower install failed" red
            return ${rc}
        fi
    fi

    # Install composer deps if missing
    if [ -f './composer.json' ] && [ ! -d './vendor' ]; then
        composer install

        rc=$?
        if [ ${rc} != 0 ]; then
            coloredEcho "<<< ($BASH_SOURCE) Composer install failed" red
            return ${rc}
        fi

    fi

    return 0
}

# --------------------------------------------------------- #
# build_site ()                                             #
# Builds the front end code via Gulp                        #
# Returns: 0 on success, NZ Error Code on error             #
# --------------------------------------------------------- #
build_site() {
    gulp build
    rc=$?
    if [ ${rc} != 0 ]; then
        coloredEcho "<<< ($BASH_SOURCE) Gulp build failed" red
        return ${rc}
    fi
    return 0
}
