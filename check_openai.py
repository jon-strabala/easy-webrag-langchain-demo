#!/usr/bin/env python3

import openai
from openai import OpenAI
import os
import sys

def check_openai_api_key(api_key):
    client = openai.OpenAI(api_key=api_key)
    try:
        client.models.list()
    except openai.AuthenticationError:
        return False
    else:
        return True

openai_api_key=os.getenv("OPENAI_API_KEY")
if len(sys.argv) > 1:
    text = sys.argv[1]
    client = OpenAI()
    print(client.embeddings.create(input = [text], model="text-embedding-ada-002").data[0].embedding)
else:
    print("Verifying openai conectivity via evars OPENAI_API_KEY")

    if check_openai_api_key(openai_api_key):
        print("Valid OpenAI API key and connectivity.\n")
        print("If you want to make an OpenAI embedding vector try:\n")

        print("\t" + sys.argv[0]+" \"what is a puma\"\n") 
    else:
        print("Invalid OpenAI API key.")
