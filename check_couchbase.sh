#!/bin/bash

# Check if all required environment variables are set
required_vars=( "CB_HOSTNAME" "CB_USERNAME" "CB_PASSWORD" )
required_ftsvars=( "CB_FTSHOSTNAME" "CB_USERNAME" "CB_PASSWORD" )

echo ""
echo "1) Verifying data service connectivity via evars ${required_vars[@]}:"

doexit=0
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set."
        doexit=1
    fi
done
for var in "${required_ftsvars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set."
        doexit=1
    fi
done
if [ "$doexit" = "1" ]; then
    exit 1
fi

# QUERY PING (not needed)
# curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_HOSTNAME}:18093/admin/ping | grep '"OK"'

# MANAGEMENT PING
curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_HOSTNAME}:18091/pools | grep "implementationVersion" > /dev/null
exit_code=$?
if [ $exit_code = "0" ] ; then
    echo "Access succeeded (port 18091), the Couchbase Server (data service) is up and running"
else
    echo "ERROR: Unable to access Couchbase Server (port 18091), check your environamt variables and your server instance"
fi

echo ""
echo "2) Verifying search service connectivity via evars ${required_ftsvars[@]}:"
# SEARCH PING
curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_FTSHOSTNAME}:18094/api/cfg | grep "status" | grep "ok" > /dev/null
exit_code=$?
if [ $exit_code = "0" ] ; then
    echo "Access succeeded (port 18094), the Couchbase Server (search service) is up and running"
else
    echo "ERROR: Unable to access Couchbase Server (port 18094), check your environamt variables and your server instance"
fi

echo ""
versionstr=`curl -s -k -u ${CB_USERNAME}:${CB_PASSWORD} https://${CB_HOSTNAME}:18091/pools/default | grep -o '"version":"[^"]*' | head -1`

# Extract version string from JSON
version=$(echo "$versionstr" | sed -n 's/.*"version":"\([0-9]\+\.[0-9]\).*/\1/p')

# Check if version is greater than or equal to 7.6
echo "3) Checking your cluster version:"
if [[ "$version" == "7.6" || "$version" > "7.6" ]]; then
    echo "Your Couchbase Version <$version> is 7.6 or later, GOOD you can run vector search applications"
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Your Couchbase Version <$version> is earlier than 7.6, ERROR sorry you can't run vector search applications"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi
echo ""

