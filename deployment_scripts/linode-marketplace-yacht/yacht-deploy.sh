#!/bin/bash
set -e
trap "cleanup $? $LINENO" EXIT

##Linode/SSH security settings
#<UDF name="user_name" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode (Recommended)" default="">

## Yacht Settings 
#<UDF name="yemail" Label="Yacht Email" example="admin@yacht.local" default="admin@yacht.local" />
#<UDF name="ypassword" Label="Yacht Password" example="Password" />
#<UDF name="compose_support" Label="Yacht Compose Support" example="Yes" default="Yes" oneof="Yes,No" />
#<UDF name="ytheme" Label="Yacht Theme" example="Default" default="Default" oneof="Default,RED,OMV" />

# git repo
export GIT_REPO="https://github.com/jcotoBan/marketplace-apps.git"
export WORK_DIR="/tmp/marketplace-apps" 
export MARKETPLACE_APP="apps/linode-marketplace-yacht"

# enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

function cleanup {
  if [ -d "${WORK_DIR}" ]; then
    rm -rf ${WORK_DIR}
  fi

}

function udf {
  local group_vars="${WORK_DIR}/${MARKETPLACE_APP}/group_vars/linode/vars"

  if [[ -n ${USER_NAME} ]]; then
    echo "username: ${USER_NAME}" >> ${group_vars};
  else echo "No username entered";
  fi

    if [[ -n ${DISABLE_ROOT} ]]; then
    echo "disable_root: ${DISABLE_ROOT}" >> ${group_vars};
  fi

  if [[ -n ${PASSWORD} ]]; then
    echo "password: ${PASSWORD}" >> ${group_vars};
  else echo "No password entered";
  fi

  if [[ -n ${PUBKEY} ]]; then
    echo "pubkey: ${PUBKEY}" >> ${group_vars};
  else echo "No pubkey entered";
  fi

  #yacht vars
  
  if [[ -n ${YEMAIL} ]]; then
    echo "yemail: ${YEMAIL}" >> ${group_vars};
  fi

  if [[ -n ${YPASSWORD} ]]; then
    echo "ypassword: ${YPASSWORD}" >> ${group_vars};
  fi

  if [[ -n ${COMPOSE_SUPPORT} ]]; then
    echo "compose_support: ${COMPOSE_SUPPORT}" >> ${group_vars};
  fi

  if [[ -n ${YTHEME} ]]; then
    echo "yacht_theme: ${YTHEME}" >> ${group_vars};
  fi
}

function run {
  # install dependancies
  apt-get update
  apt-get install -y git python3 python3-pip

  # clone repo and set up ansible environment
  git -C /tmp clone --depth 1 --filter=blob:none ${GIT_REPO} --branch yacht --sparse
  cd ${WORK_DIR}
  git sparse-checkout init --cone
  git sparse-checkout set apps/linode-marketplace-yacht apps/linode_helpers

  # venv
  cd ${WORK_DIR}/${MARKETPLACE_APP}
  pip3 install virtualenv
  python3 -m virtualenv env
  source env/bin/activate
  pip install pip --upgrade
  pip install -r requirements.txt
  ansible-galaxy install -r collections.yml

  # populate group_vars
  udf
  # run playbooks
  for playbook in site.yml; do ansible-playbook -vvvv $playbook; done
  
}

function installation_complete {
  echo "Installation Complete"
}
# main
run && installation_complete
cleanup
