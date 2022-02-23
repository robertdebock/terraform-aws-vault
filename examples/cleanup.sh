#!/bin/bash -x

# A script to cleanup all local files and regenerate files required.

for scenario in * ; do
  if [ -d "${scenario}" ] ; then
    cd "${scenario}"
    for file in id_rsa id_rsa.pub terraform.tfstate terraform.tfstate.backup ; do
      rm "${file}"
    done
    ssh-keygen -b 2048 -f id_rsa -q -N ""
    ./vault-tls.sh
    terraform init
    cd ../
  fi
done
