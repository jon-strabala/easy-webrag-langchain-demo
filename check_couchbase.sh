#!/bin/bash

PATH=${CB_HOME}:$PATH

# Check if all required environment variables are set
required_vars=("CB_HOME" "CB_HOSTNAME" "CB_USERNAME" "CB_PASSWORD" )

echo "Verifying database conectivity via evars ${required_vars[@]}"

doexit=0
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set."
        doexit=1
    fi
done
if [ "$doexit" = "1" ]; then
    exit 1
fi

${CB_HOME}/bin/couchbase-cli host-list --no-ssl-verify -c couchbases://${CB_HOSTNAME} -u ${CB_USERNAME} -p ${CB_PASSWORD}
exit_code=$?
if [ $exit_code = "0" ] ; then
    echo "Access suceeded, the Couchbase Server is up and running"
else
    echo "ERROR: Unable to access Couchbase Server, check your environamt variables and your server instance"
fi

