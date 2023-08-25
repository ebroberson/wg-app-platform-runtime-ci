#!/bin/bash

function verify_go(){
    go version
}
function verify_gofmt(){
    files=$(gofmt -l . | grep -v vendor || true) && [ -z "$files" ]
}
function verify_govet(){
    go vet ./...
}

function expand_flags(){
    debug "expand_flags Starting"
    local list=""
    IFS=$'\n'
    for entry in ${FLAGS}
    do
        list="${list}${entry} "
    done
    debug "running with flags: ${list}"
    debug "expand_flags Ending"
    echo "${list}"
}

function expand_envs(){
    local env_file="${1?path to env file}"
    debug "expand_envs Starting"
    IFS=$'\n'
    for entry in ${ENVS}
    do
        local key=$(echo $entry | cut -d '=' -f1)
        local value=$(echo $entry | cut -d '=' -f2)
        echo "Setting env: $key=$value"
        echo "export $key=$value" >> "${env_file}"
    done
    debug "expand_envs Ending"
}

function expand_functions(){
    debug "expand_functions Starting"
    IFS=$'\n'
    for entry in ${FUNCTIONS}
    do
        echo "Sourcing: $entry"
        source $entry
    done
    debug "expand_functions Ending"
}

function expand_verifications(){
    debug "expand_verifications Starting"
    for entry in ${VERIFICATIONS}
    do
        echo "Verifying: $entry"
        $entry
    done
    debug "expand_verifications Ending"
}

function debug(){
    local msg="${1:-}"
    if [[ "${DEBUG:=false}" != "false" ]]; then
        echo "$msg" >> "/tmp/$TASK_NAME.log"
    fi
}

function init_git_author(){
    git config --global user.name "${GIT_COMMIT_USERNAME:=App Platform Runtime Working Group CI Bot}"
    git config --global user.email "${GIT_COMMIT_EMAIL:=app+platform+runtime+wg+ci@vmware.com}"
}

function err_reporter() {
    echo "---Debug Report Starting--"
    cat "/tmp/$TASK_NAME.log"
    echo "---Debug Report Ending--"
}

