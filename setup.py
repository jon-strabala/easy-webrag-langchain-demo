#!/usr/bin/env python3

import os
import sys
import requests
import time
from requests.auth import HTTPBasicAuth
from requests.packages.urllib3.exceptions import InsecureRequestWarning

from couchbase.cluster import Cluster
from couchbase.options import ClusterOptions
from couchbase.auth import PasswordAuthenticator
from couchbase.exceptions import BucketNotFoundException, ScopeNotFoundException, InternalServerFailureException
from couchbase.exceptions import UnAmbiguousTimeoutException, AuthenticationException
from couchbase.management.buckets import BucketManager
from couchbase.management.buckets import CreateBucketSettings
from couchbase.management.collections import CollectionSpec
from couchbase.management.buckets import BucketType, ConflictResolutionType

def process_template_to_json(search_index_name, bucket_name, scope_name, collection_name):
    # Define the path of the input template and the output JSON file
    template_file_path = 'search_indexdef.tmpl'
    output_file_path = 'search_indexdef.json'
    
    try:
        # Open the template file for reading
        with open(template_file_path, 'r') as template_file:
            # Read the content of the template file
            content = template_file.read()
            
            # Substitute the placeholders with the provided variable values
            content = content.replace('_CB_SEARCHINDEX_', search_index_name)
            content = content.replace('_CB_BUCKET_', bucket_name)
            content = content.replace('_CB_SCOPE_', scope_name)
            content = content.replace('_CB_COLLECTION_', collection_name)
            
        # Open the output JSON file for writing
        with open(output_file_path, 'w') as output_file:
            # Write the processed content to the output file
            output_file.write(content)
            
        print("Template processing completed successfully, made index definition file 'search_indexdef.json'.")
        
    except IOError as e:
        print(f"An error occurred while processing the template: {e}")


def update_search_index(cb_username, cb_password, cb_hostname, cb_bucket, cb_scope, cb_searchindex):
    # Construct the URL for the PUT request
    url = f"https://{cb_hostname}:18094/api/bucket/{cb_bucket}/scope/{cb_scope}/index/{cb_searchindex}"
    
    # Load the JSON data from file
    with open("./search_indexdef.json", "r") as file:
        json_data = file.read()
    
    # Make the PUT request
    response = requests.put(
        url,
        headers={"Content-Type": "application/json"},
        auth=HTTPBasicAuth(cb_username, cb_password),
        data=json_data,
        verify=False  # Use this to skip SSL verification, equivalent to curl's -k option
    )
    
    # Check the response status
    if response.ok:
        print("Index update successful.")
    else:
        print(f"Failed to update index. Status code: {response.status_code}, Response: {response.text}")


def get_bucket(cluster, bucket_name):
    try:
        # Attempt to open the bucket
        bucket = cluster.bucket(bucket_name)
        # Optionally, you could add a readiness check here with bucket.wait_until_ready(timeout)
        return bucket
    except BucketNotFoundException as e:
        # Bucket not found, raise the exception to be handled by the caller
        return None
    except Exception as e:
        # For any other exception, raise it to be handled by the caller
        raise Exception(f"An error occurred while accessing the bucket: {e}") from e


def get_scope(collection_mgr, scope_name):
    return next((s for s in collection_mgr.get_all_scopes()
                if s.name == scope_name), None)


def get_collection(collection_mgr, scope_name, coll_name):
    scope = get_scope(collection_mgr, scope_name)
    if scope:
        return next(
            (c for c in scope.collections if c.name == coll_name),
            None)

    return None

# Suppress only the single InsecureRequestWarning from urllib3 needed for unverified HTTPS requests
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

try:
    pa = PasswordAuthenticator(os.getenv("CB_USERNAME"), os.getenv("CB_PASSWORD"))
    cluster = Cluster("couchbases://" + os.getenv("CB_HOSTNAME") + "/?ssl=no_verify", ClusterOptions(pa))
except UnAmbiguousTimeoutException as e:
    print(f"Failed to connect to couchbases://" + os.getenv("CB_HOSTNAME") + "/?ssl=no_verify due to UnAmbiguousTimeoutException.")
    print(f"Check that CB_HOSTNAME is set and that your IP is allowed to access the target service.")
    sys.exit(1)
except AuthenticationException as e:
    print(f"Incorrect authentication configuration, bucket doesn't exist or bucket may be hibernated due to AuthenticationException.")
    print(f"Check that CB_USERNAME and CB_PASSWORD are set and a legal user on OnPrem or a configured Capella database user.")
    sys.exit(1)
except Exception as e:
    print(f"An error occurred: {e}")


bucket_name = os.getenv("CB_BUCKET")
scope_name = os.getenv("CB_SCOPE")
collection_name = os.getenv("CB_COLLECTION")
search_index_name = os.getenv("CB_SEARCHINDEX")

bucket_manager = cluster.buckets()

bucket = get_bucket(cluster, bucket_name)
if bucket == None:
    print(f"Bucket '{bucket_name}' is missing.")
    try:
        bucket_manager.create_bucket(
            CreateBucketSettings(
                name=bucket_name,
                flush_enabled=True,
                ram_quota_mb=100,
                num_replicas=0,
                bucket_type=BucketType.COUCHBASE,
                conflict_resolution_type=ConflictResolutionType.SEQUENCE_NUMBER))
        time.sleep(1)
        print(f"Bucket '{bucket_name}' created successfully.")
        bucket = get_bucket(cluster, bucket_name)
    except InternalServerFailureException as e:
        error_message = str(e)
        if "Forbidden. User needs the following permissions" in error_message and "cluster.buckets!create" in error_message:
            print("Permission error detected. The user does not have the required permissions to create a bucket.")
            print(f"Bucket '{bucket_name}' does not exist. You will need to create it in your OnPrem Server or Capella UI.")
            sys.exit(0)
        else:
            print(f"An internal server error occurred: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

else:
    print(f"Bucket '{bucket_name}' is present.")

collections_manager = bucket.collections()
coll_manager = bucket.collections()

if get_scope(collections_manager, scope_name) == None:
    print(f"Scope '{scope_name}' is missing.")
    collections_manager.create_scope(scope_name)
    print(f"Scope '{scope_name}' created successfully.")
    time.sleep(1)
else:
    print(f"Scope '{scope_name}' is present.")

have_collection = False
if get_collection(collections_manager, scope_name, collection_name) == None:
    print(f"Collection '{collection_name}' is missing.")
    # collection_spec = CollectionSpec( collection_name, scope_name=scope_name )
    # collections_manager.create_collection(collection_spec)
    collections_manager.create_collection(scope_name, collection_name)
    print(f"Collection '{collection_name}' created successfully.")
    time.sleep(1)
else:
    print(f"Collection '{collection_name}' is present.")
    have_collection = True

process_template_to_json(search_index_name, bucket_name, scope_name, collection_name)


if have_collection:
    user_input = input("Do you want to clear out your data? (yes/y): ").upper()
    if user_input == "YES" or user_input == "Y":
        collections_manager.drop_collection(scope_name, collection_name)
        print(f"Collection '{collection_name}' dropped successfully.")
        time.sleep(1)
        collections_manager.create_collection(scope_name, collection_name)
        print(f"Collection '{collection_name}' created successfully.")
        time.sleep(1)
        update_search_index(os.getenv("CB_USERNAME"), os.getenv("CB_PASSWORD"), os.getenv("CB_FTSHOSTNAME"), bucket_name, scope_name, search_index_name)
        print(f"Search index '{search_index_name}' created successfully.")
else:
    # create index
    update_search_index(os.getenv("CB_USERNAME"), os.getenv("CB_PASSWORD"), os.getenv("CB_FTSHOSTNAME"), bucket_name, scope_name, search_index_name)
    print(f"Search index '{search_index_name}' created successfully.")


