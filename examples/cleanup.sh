#!/bin/bash

# A script to cleanup all local files and regenerate files required.

for scenario in * ; do
  if [ -d "${scenario}" ] ; then
    echo "Working on scenario: ${scenario}."
    cd "${scenario}"
    if [ -d prerequisites ] ; then
      echo "Working on prerequisites."
      cd prerequisites
      terraform destroy -auto-approve
      for file in terraform.tfstate terraform.tfstate.backup ; do
        test -f "${file}" && (echo "Removing file ${file}." ; rm "${file}")
      done
      for directory in .terraform ; do
        test -d "${directory}" && (echo "Removing directory ${directory}" ; rm -Rf "${directory}")
      done
      echo "Running terraform init."
      terraform init
      echo "Running terraform fmt."
      terraform fmt
    fi
    terraform destroy -auto-approve
    for file in id_rsa id_rsa.pub init.txt terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl ; do
      test -f "${file}" && (echo "Removing ${file}." ; rm "${file}")
    done
    for directory in .terraform ; do
      test -d "${directory}" && (echo "Removing directory ${directory}" ; rm -Rf "${directory}")
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
