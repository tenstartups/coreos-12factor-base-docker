#!/bin/bash
set -e

# Set environment variables
ETCD_ENVIRONMENT_VARIABLE_REGEX="^\s*ETCD2ENV_([_A-Z0-9]+)=(.+)\s*$"
ENV_FILE="<%= getenv!(:config_directory) %>/env/etcd2env.env"

# Wait for etcd service to respond before proceeding
until /usr/bin/etcdctl ls --recursive >/dev/null 2>&1; do
  echo "Waiting for etcd to start responding..."
  failures=$((failures+1))
  if [ ${failures} -gt 20 ]; then
    echo >&2 "Timed-out waiting for etcd to start responding."
    exit 1
  fi
  sleep 5
done

# Wait for keys to be bootstrapped if this is the first machine in the cluster
while [ -z "$(/usr/bin/etcdctl ls --recursive)" ]; do
  echo "Waiting for initial etcd bootstrap keys..."
  attempts=$((attempts+1))
  if [ ${attempts} -gt 20 ]; then
    echo >&2 "Timed-out waiting for initial etcd bootstrap keys."
    exit 1
  fi
  sleep 15
done

# Dump out the entire tree
/usr/bin/etcdctl ls --recursive

# Build a combined environment file for use in systemd services
cat << EOF > "${ENV_FILE}"
# Do not edit this file.  It is automatically generated by the etcd2env service
EOF
while read -r env_name etcd_variable ; do
  env_value=$(/usr/bin/etcdctl get "${etcd_variable}")
  if [ -z "${env_value}" ]; then
    echo >&2 "Unable to load ${etcd_variable} variable from etcd."
    exit 1
  fi
  echo "${env_name}=${env_value}" >> "${ENV_FILE}"
done < <(env | grep -E "${ETCD_ENVIRONMENT_VARIABLE_REGEX}" | sed -E "s/${ETCD_ENVIRONMENT_VARIABLE_REGEX}/\1 \2/" | sort | uniq)
