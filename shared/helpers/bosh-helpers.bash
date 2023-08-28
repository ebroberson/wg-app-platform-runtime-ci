function bosh_target(){
    eval "$(bbl print-env --metadata-file toolsmiths-env/metadata)"
    export TOOLSMITHS_ENVIRONMENT_NAME="$(cat toolsmiths-env/name)"
}

function bosh_manifest(){
    bosh -d "$(bosh_cf_deployment_name)" manifest
}

function bosh_cf_deployment_name(){
    bosh ds --column=name --json | jq -r '.Tables[].Rows[] | select (.name |contains("cf")).name'
}

function bosh_extract_manifest_defaults_from_cf(){
    local manifest="${1:?Provide a manifest}"
    echo  "export CF_STEMCELL_OS=$(bosh int $manifest --path /stemcells/alias=default/os)
export CF_AZ=$(bosh int $manifest --path /instance_groups/0/azs/0)
export CF_NETWORK=$(bosh int $manifest --path /instance_groups/0/networks/0/name)
export CF_VM_TYPE=$(bosh int $manifest --path /instance_groups/0/vm_type)"
export JUNk="addd"
}

function bosh_extract_vars_from_env_files(){
    local files=${@}
    debug "Creating bosh vars files from the following files: $files"
    local arguments=""
    IFS=$' '
    for file in ${files}
    do
        debug "Adding arugment for file: $file"
        IFS=$'\n'
        for entry in $(cat $file)
        do
            local key=$(echo ${entry} | cut -d "=" -f1 | cut -d " " -f2)
            eval $entry
            arguments="${arguments} --var=${key}=${!key}"
        done
    done
    echo ${arguments}
}
