function bosh_target(){
    #This relies on toolsmiths-env and cf-deployment-concourse-tasks resources
    source cf-deployment-concourse-tasks/shared-functions
    eval "$(bbl print-env --metadata-file toolsmiths-env/metadata)"
}

function bosh_manifest(){
    bosh -d "$(bosh_cf_deployment_name)" manifest
}

function bosh_cf_deployment_name(){
    bosh ds --column=name --json | jq -r '.Tables[].Rows[] | select (.name |contains("cf")).name'
}
