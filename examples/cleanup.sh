#!/bin/bash

# A script to cleanup all local files and regenerate files required.

delete_object() {
  if [ -z "${1}" ] ; then
    echo "Please pass an object to this function."
    exit 1
  fi
  
  if [ -f "${1}" ] ; then
     echo "Removing file ${1}."
     rm "${1}"
  fi

  if [ -d "${1}" ] ; then
    echo "Removing directory ${1}."
    rm -Rf "${1}"
  fi
}

for scenario in * ; do
  if [ -d "${scenario}" ] ; then
    echo "Working on scenario: ${scenario}." ; cd "${scenario}"
    if [ -d prerequisites ] ; then
      echo "Working on prerequisites."
      cd prerequisites
      terraform destroy -auto-approve
      for object in terraform.tfstate terraform.tfstate.backup .terraform ; do
        delete_object "${object}"
      done
      echo "Running terraform init."
      terraform init
      echo "Running terraform fmt."
      terraform fmt
      cd ../
    fi
    terraform destroy -auto-approve
    for object in id_rsa id_rsa.pub init.txt terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl .terraform ; do
      delete_object "${object}"
    done
    echo "Generating ssh-key."
    ssh-keygen -b 2048 -f id_rsa -q -N ""
    echo "Generate TLS material."
    ./vault-tls.sh
    echo "Running terraform init."
    terraform init
    echo "Running terraform fmt."
    terraform fmt
    cd ../
  fi
done
