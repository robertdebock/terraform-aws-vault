#!/bin/sh

# A function to instruct on usage.
usage() {
  echo "$0 -a AUDIT_DEVICE_PATH -s AUDIT_DEVICE_SIZE"
  echo ""
  exit 1
}

# Read the specified arguments.
while getopts :a:s: flag ; do
  case "${flag}" in
    a)
      audit_device_path="${OPTARG}"
    ;;
    s)
      audit_device_size="${OPTARG}"
    ;;
    \?)
      echo "The option ${OPTARG} is invalid."
      exit 1
    ;;
    :)
     echo "The argument ${OPTARG} is unknown."
     exit 1
    ;;
  esac
done

# Check that the audit_device_path is set.
if [ -z "${audit_device_path}" ] ; then
  echo "Please specify an audit device path."
  echo ""
  usage
fi

# Check that the audit_device_size is set.
if [ -z "${audit_device_size}" ] ; then
  echo "Please specify an audit device size."
  echo ""
  usage
fi

cat << EOF > /etc/logrotate.d/vault
${audit_device_path}/*.log {
  rotate $[${audit_device_size}]
  missingok
  compress
  size 512M
  postrotate
    /usr/bin/systemctl reload vault 2> /dev/null || true
  endscript
}
EOF

# Run logrotate hourly.
cp /etc/cron.daily/logrotate /etc/cron.hourly/logrotate
