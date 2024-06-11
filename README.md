## RAG Demo using Couchbase, Streamlit, Langchain, and OpenAI

This is a demo app built to chat with your custom PDFs using the vector search capabilities of Couchbase to augment the OpenAI results in a Retrieval-Augmented-Generation (RAG) model.

The demo will run for both self-managed OnPrem 7.6+ Couchbase deployments and also clould based 7.6+ Capella deployments

If you don't have the time to run the demo you can just download and watch the 7 minute video: [easy-webrag-langchain-demo_1920x1080.mp4](https://github.com/jon-strabala/easy-webrag-langchain-demo/blob/main/easy-webrag-langchain-demo_1920x1080.mp4) 

### Prerequisites 

You will need a database user with login credentials to your Couchbase cluster and an OpenAI API bearer key for this Linux demo

You will probably want to create and activate a virtual environment using the standard library's virtual environment tool, *venv*, and install local python packages.

- https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/

Quick tips on Python virtual environments (please folow this unless you are an expert). 

- Create and activate a virtual environment in a new empty demo directory<br><br>
`mkdir MYDEMO`<br>
`cd MYDEMO`<br>
`python3 -m venv .venv`<br>
`source .venv/bin/activate`

- The above works for *bash* or *zsh*, however you would use `. .venv/bin/activate` if you are using *sh*

- Then, when all done with this demo, you can deactivate it.<br><br>
`deactivate`

- Just in case you typed 'deactive' (you do this deactive when you're done with the full demo) - just run the source command again to reactivate the virtual Python environment:<br><br>
`source .venv/bin/activate`

- The above works for *bash* or *zsh*, however you would use `. .venv/bin/activate` if you are using *sh*

- Now download this git repo and cd into it.<br><br>
`git clone https://github.com/jon-strabala/easy-webrag-langchain-demo.git`<br>
`cd easy-webrag-langchain-demo`

### How does this demo work?

You can upload your PDFs with custom data & ask questions about the data in the chat box.

For each question, you will get two answers:

- one using RAG (Couchbase logo)
- one using pure LLM - OpenAI (🤖).

For RAG, we are using LangChain, Couchbase Vector Search & OpenAI. We fetch parts of the PDF relevant to the question using Vector search & add it as the context to the LLM. The LLM is instructed to answer based on the context from the Vector Store.

### How to Configure

- Install dependencies

  `pip install -r requirements.txt`

- Copy the template environment template

  `cp _setup.tmpl _setup`

- Required environment variables that you must configure in _setup
  ```
  export CB_HOSTNAME="<the hostname or IP address of your Couchbase server>"
  export CB_FTSHOSTNAME="<the hostname or IP address of a node running Search in your Couchbase cluster>"
  export CB_USERNAME="<username_for_couchbase_cluster>" 
  export CB_PASSWORD="<password_for_couchbase_cluster>"
  export OPENAI_API_KEY="<open_ai_api_key>"
  export WEB_LOGIN_PASSWORD="<password to access the streamlit app or ChatBot>"
  ```

- Note CB_HOSTNAME might be different than CB_FTSHOSTNAME if your services are distributed (these are the same on a single node cluster).
  - The evar CB_HOSTNAME is typically an IP in your cluster (or the Capella CONNECT hostname) running the data service (or KV) for the Python SDK to connect to couchbases://${CB_HOSTNAME}. 
  - The evar CB_FTSHOSTNAME is set to a node running the search service (or fts) for a curl like connection to https://${CB_FTSHOSTNAME}:18094 used for index creation.
  - This example always uses and assumes secure connections to your couchbase instance, you should verify your firewall will pass at least 18091 (Management port), 18094 (Search service), 11210 / 11207 (Data service)

- Optional environment variables that you may alter in _setup

  ```
  export CB_BUCKET=vectordemos
  export CB_SCOPE=langchain
  export CB_COLLECTION=webrag
  export CB_SEARCHINDEX=webrag_index
  ```

- Source the _setup file (we assume a bash shell)

  `source _setup`

- The above works for *bash* or *zsh*, however you would use `. _setup` if you are using *sh*

- If needed set the executable bit via chmod for the following:

  `chmod +x check_couchbase.sh  check_openai.py  setup.py`

- Verify connectivity and authentication to your Couchbase server

  `./check_couchbase.sh`

- Verify connectivity and authentication to OpenAI

  `./check_openai.py`

- Setup the Couchbase infrastructure (bucket, scope, collection and a search vector index) via the bash script

  `./setup.py`

### Run the application this will start a webserver

  `streamlit run chat_with_pdf.py`

Now open the URL displayed in a web browser

- Login by supplying the WEB_LOGIN_PASSWORD and hit the "Submit" button.

Load your PDF(s) into the Couchbase Vector Store. 

- Hit the "Browse Files" button and upload one or more PDFs that you wish to form your corpus of knowledge.
  
- For each PDF file you will also have to hit the "Upload & Vectorize" button. Upon completion the number of documents split up from the PDF will be listed below the "Upload & Vectorize" button.

Interact with your PDF. 

- In the bottom of the web page where it says "Ask a question based on the PDF(s)" start asking questions.

### Other

To remove your corpus (documents based on your PDF(s) you can kill your streamlit web app via ctrl-C, then  
can run `./setup.py` again if the bucket already exists you will get an option to reset your collection (drop/create) and readd your search index.

### Finished

When you are all done with this demo, you should deactivate the python virtual environment (you can always reactivate it later).<br><br>
`deactivate`
