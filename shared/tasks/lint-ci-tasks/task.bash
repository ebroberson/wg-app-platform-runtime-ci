#!/bin/bash

# set -eEu
# # set -o pipefail

# THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# export TASK_NAME="$(basename $THIS_FILE_DIR)"
# source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
# unset THIS_FILE_DIR

# fragile for loops on find
# shellcheck disable=SC2044 

FOUND_ERROR=false
function run() {
    image_resource
    find_search_terms_linux
    params_match
    extra_inputs_match
    metadata_checks
    allowed_files
    no_files_in_task_root
    run_platform_match


    if [[ ${FOUND_ERROR} == true ]]; then
        echo "Errors found, please review"
    fi
}

# image_resource
function image_resource() {
    for file in $(find . -name "linux.yml" )
    do
        if [[ $(yq .image_resource "${file}") != "null" ]]; then
            echo "Found image_resource in ${file}. Please remove that and use 'image' to inject into the task at runtime."
            FOUND_ERROR=true
        fi
    done

}
# TASK_NAME
function find_search_terms_windows() {
    # don't expand expression
    # shellcheck disable=SC2016
    local search_terms='$TASK_NAME'
    for file in $(find . -name "task.ps1")
    do
        IFS=$'\n'
        for search_term in ${search_terms}
        do
            local found
            found=$(grep "${search_term}" "${file}")

            if [[ $? == 1 ]]; then
                echo "${search_term} not found in ${file}"
                FOUND_ERROR=true
            fi
        done
    done
}

function find_search_terms_linux() {
    # don't expand expression
    # shellcheck disable=SC2016
    local search_terms='set -eEu
set -o pipefail
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
err_reporter $LINENO
run()
'

    for file in $(find . -name "task.bash")
    do
        IFS=$'\n'
        for search_term in ${search_terms}
        do
            local found
            # found not used because we don't want to execute grep output
            # shellcheck disable=SC2034
            found=$(grep "${search_term}" "${file}")

            if [[ $? == 1 ]]; then
                echo "${search_term} not found in $file"
                FOUND_ERROR=true
            fi
        done
    done
}

function params_match() {
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "${dir}/linux.yml" ]]; then
            local same
            same="$(yq eval-all '[.params | keys] | .[0] - .[1]' "${dir}"/linux.yml "${dir}"/metadata.yml)"
            if [[ "${same}" != "[]" ]] && [[ "${same}" != "null" ]]; then
                echo "params are not matching for ${dir} task according to metadata.yml and linux.yml"
                FOUND_ERROR=true
            fi
        fi
        if [[ -f "$dir/windows.yml" ]]; then
            local same
            same="$(yq eval-all '[.params | keys] | .[0] - .[1]' "${dir}"/windows.yml "${dir}"/metadata.yml)"
            if [[ "${same}" != "[]" ]] && [[ "${same}" != "null" ]]; then
                echo "params are not matching for $dir task according to metadata.yml and windows.yml"
                FOUND_ERROR=true
            fi
        fi
    done
}

# don't call this one directly from run()
# it is called by extra_inputs_match
function intersect_inputs() {
    local set1=${1}
    local set2=${2}

    IFS=$'\n'
    for set1_input in ${set1}
    do
        local input_found=false
        for set2_input in ${set2}
        do
            if [[ "${set1_input}" =~ ${set2_input} ]]; then
                input_found=true
            elif [[ "${set2_input}" =~ ${set1_input} ]]; then
                input_found=true
            fi
        done

        if [[ ${input_found} == false ]]; then
            echo "Could not find ${set1_input} in ${set2} when checking ${set1} " 
        fi
    done
}
function extra_inputs_match() {
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "$dir/linux.yml" ]]; then
            local metadata_inputs
            metadata_inputs="$(yq -r '.extra_inputs | select(.) | keys | .[]' "${dir}"/metadata.yml)"
            local optional_inputs
            optional_inputs="$(yq -r '.inputs[] | select(.optional==true) | .name' "${dir}"/linux.yml)"

            intersect_inputs "${metadata_inputs}" "${optional_inputs}"
            intersect_inputs "${optional_inputs}" "${metadata_inputs}" 
        fi
    done
}
function metadata_checks() {
    for file in $(find . -name "metadata.yml")
    do
        if [[ $(yq '.readme' "${file}") == 'null' ]]; then
            echo "No readme found in ${file}"
            FOUND_ERROR=true
        fi

        if [[ $(yq '.oses' "${file}") == 'null' ]]; then
            echo "No oses found in ${file}"
            FOUND_ERROR=true
        fi
    done
}

function allowed_files() {
    local filenames='metadata.yml
linux.yml
windows.yml
task.bash
task.ps1
'
    IFS=$'\n'
    for filepath in $(find . -ipath "*tasks/*/*" -type f)
    do
        local file
        file=$(basename "${filepath}")
        # literal regex matching
        # shellcheck disable=2076
        if ! [[ "${filenames[*]}" =~ "${file}" ]]; then
            echo "File ${filepath} is not allowed"
            FOUND_ERROR=true
        fi
    done
}

function no_files_in_task_root() {
    pushd tasks > /dev/null || return
    for filepath in $(find . -maxdepth 1 -type f)
    do
        local file
        file=$(basename "${filepath}")
        echo "File ${file} found in task root"
        FOUND_ERROR=true
    done
    popd > /dev/null || return
}

function run_platform_match() {
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "${dir}/linux.yml" && ! -f "${dir}/task.bash" ]]; then
            echo "Task $(basename "${dir}") has a Linux config and no Bash file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/linux.yml" && -f "${dir}/task.bash" ]]; then
            echo "Task $(basename "${dir}") has a Bash file and no Linux config"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/windows.yml" && ! -f "${dir}/task.ps1" ]]; then
            echo "Task $(basename "${dir}") has a Windows config and no Powershell file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/windows.yml" && -f "${dir}/task.ps1" ]]; then
            echo "Task $(basename "${dir}") has a Powershell file and no Windows config"
            FOUND_ERROR=true
        fi
    done
}

#trap 'err_reporter $LINENO' ERR
#run "$@"
