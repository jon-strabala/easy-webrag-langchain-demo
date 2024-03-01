#!/bin/bash

PATH=${CB_HOME}:$PATH

# Check if all required environment variables are set
required_vars=("CB_HOME" "CB_HOSTNAME" "CB_USERNAME" "CB_PASSWORD" "CB_BUCKET" "CB_SCOPE" "CB_COLLECTION" "CB_SEARCHINDEX" "OPENAI_API_KEY")
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

check=`${CB_HOME}/bin/couchbase-cli bucket-list  --no-ssl-verify -c couchbases://${CB_HOSTNAME} -u ${CB_USERNAME} -p ${CB_PASSWORD} | egrep '(^'${CB_BUCKET}')'`
if [ "$check" = "$CB_BUCKET" ] ; then
    echo 'Note bucket "'$CB_BUCKET'" exists will flush'
    ${CB_HOME}/bin/couchbase-cli bucket-flush --no-ssl-verify -c couchbases://${CB_HOSTNAME} --bucket ${CB_BUCKET} \
        -u ${CB_USERNAME} -p ${CB_PASSWORD} 
else
    echo 'Create a bucket "'$CB_BUCKET'" we will use the keyspace "'${CB_BUCKET}.${CB_SCOPE}.${CB_COLLECTION}'"'
    ${CB_HOME}/bin/couchbase-cli bucket-create --no-ssl-verify -c couchbases://${CB_HOSTNAME} --bucket $CB_BUCKET \
        -u ${CB_USERNAME} -p ${CB_PASSWORD} \
        --bucket-eviction-policy fullEviction \
        --enable-flush 1 --bucket-ramsize 500 \
        --bucket-replica 0 --bucket-type couchbase \
        --storage-backend couchstore --wait
    sleep 1
fi

check=`${CB_HOME}/bin/couchbase-cli collection-manage --list-scopes --no-ssl-verify -c couchbases://${CB_HOSTNAME} --bucket ${CB_BUCKET} -u ${CB_USERNAME} -p ${CB_PASSWORD} | grep $CB_SCOPE`
if [ "$check" = "$CB_SCOPE" ] ; then
    # echo 'Note scope "'$CB_SCOPE'" exists'
    have_scope=1
else
    echo 'Create a scope "'$CB_SCOPE'" we will use the keyspace "'${CB_BUCKET}.${CB_SCOPE}.${CB_COLLECTION}'"'
    ${CB_HOME}/bin/couchbase-cli collection-manage --create-scope ${CB_SCOPE} --no-ssl-verify \
	-c couchbases://${CB_HOSTNAME} --bucket ${CB_BUCKET} -u ${CB_USERNAME} -p ${CB_PASSWORD}
    sleep 1
fi

check=`${CB_HOME}/bin/couchbase-cli collection-manage --list-collections ${CB_SCOPE} --no-ssl-verify -c couchbases://${CB_HOSTNAME} --bucket ${CB_BUCKET} -u ${CB_USERNAME} -p ${CB_PASSWORD} | grep ${CB_COLLECTION} | awk '{print $NF}'`
if [ "$check" = "$CB_COLLECTION" ] ; then
    # echo 'Note collection "'$CB_COLLECTION'" exists'
    have_collection=1
else
    echo 'Create a collection "'$CB_COLLECTION'" we will use the keyspace "'${CB_BUCKET}.${CB_SCOPE}.${CB_COLLECTION}'"'
    ${CB_HOME}/bin/couchbase-cli collection-manage --create-collection ${CB_SCOPE}.${CB_COLLECTION} \
	--no-ssl-verify -c couchbases://${CB_HOSTNAME} --bucket ${CB_BUCKET} -u ${CB_USERNAME} -p ${CB_PASSWORD}
    sleep 1
fi

if curl -s -k -XGET -H "Content-Type: application/json" \
    -u ${CB_USERNAME}:${CB_PASSWORD} \
    https://$CB_HOSTNAME:18094/api/bucket/${CB_BUCKET}/scope/${CB_SCOPE}/index \
    | grep -q '"'${CB_BUCKET}.${CB_SCOPE}.${CB_SEARCHINDEX}'":'; then

    # echo 'Note scoped index "'${CB_SEARCHINDEX}'" exists'
    have_searchindex=1
else
    # make the endex from the template
    cat search_indexdef.tmpl | \
	sed -e 's/_CB_BUCKET_/'${CB_BUCKET}'/g' | \
	sed -e 's/_CB_SCOPE_/'${CB_SCOPE}'/g' | \
	sed -e 's/_CB_COLLECTION_/'${CB_COLLECTION}'/g' | \
	sed -e 's/_CB_SEARCHINDEX_/'${CB_BUCKET}.${CB_SCOPE}.${CB_SEARCHINDEX}'/g' \
        > search_indexdef.json 

    echo 'Load the scoped index definition in the scope "'${CB_BUCKET}.${CB_SCOPE}'" and name it "'${CB_SEARCHINDEX}'"'
    curl -s -k -XPUT -H "Content-Type: application/json" -u ${CB_USERNAME}:${CB_PASSWORD}  \
        https://$CB_HOSTNAME:18094/api/bucket/${CB_BUCKET}/scope/${CB_SCOPE}/index/${CB_SEARCHINDEX} -d @./search_indexdef.json
fi

# curl -s -k -XGET -H "Content-Type: application/json" -u ${CB_USERNAME}:${CB_PASSWORD} https://$CB_HOSTNAME:18094/api/bucket/${CB_BUCKET}/scope/${CB_SCOPE}/index | grep '"'${CB_BUCKET}.${CB_SCOPE}.${CB_SEARCHINDEX}'":' > /dev/null

