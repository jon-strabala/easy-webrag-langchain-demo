#!/bin/bash

# Check if all required environment variables are set
required_vars=( "CB_HOSTNAME" "CB_USERNAME" "CB_PASSWORD" )

echo ""
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

curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_HOSTNAME}:18093/admin/ping | grep '"OK"'
exit_code=$?
if [ $exit_code = "0" ] ; then
    echo "Access suceeded, the Couchbase Server is up and running"
else
    echo "ERROR: Unable to access Couchbase Server, check your environamt variables and your server instance"
fi

echo ""
versionstr=`curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_HOSTNAME}:18091/pools/default | grep -o '"version":"[^"]*' | head -1`

# Extract version string from JSON
version=$(echo "$versionstr" | grep -oP '(?<="version":")[^"]+')

# Check if version is greater than or equal to 7.6
if [[ "$version" == "7.6" || "$version" > "7.6" ]]; then
    echo "Your Couchbase Version <$version> is 7.6 or later, GOOD you can run vector search appications"
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Your Couchbase Version <$version> is earlier than 7.6, ERROR sorry you can't run vector search appications"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi
echo ""
