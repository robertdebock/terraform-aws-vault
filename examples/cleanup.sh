#!/bin/bash

# A script to cleanup all local files and regenerate files required.

for scenario in * ; do
  if [ -d "${scenario}" ] ; then
    cd "${scenario}"
    for file in id_rsa id_rsa.pub init.txt terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl user_data.sh bastion_user_data.sh ; do
      test -f "${file}" && rm "${file}"
    done
    for directory in .terraform ; do
      test -d "${directory}" && rm -Rf "${directory}"
    done
    ssh-keygen -b 2048 -f id_rsa -q -N ""
    ./vault-tls.sh
    terraform init
    cd ../
  fi
done
