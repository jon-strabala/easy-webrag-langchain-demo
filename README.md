## RAG Demo using Couchbase, Streamlit, Langchain, and OpenAI

This is a demo app built to chat with your custom PDFs using the vector search capabilities of Couchbase to augment the OpenAI results in a Retrieval-Augmented-Generation (RAG) model.

### Prerequisites 

You will need admin privileges for your onprem Couchbase server 
and an OpenAI API bearer key for this Linux demo

You probably want to create and activate a virtual environment using the standard library’s virtual environment tool venv and install packages.

- https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/
- 
### How does it work?

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
  export CB_USERNAME="<username_for_couchbase_cluster>" 
  export CB_PASSWORD="<password_for_couchbase_cluster>"
  export OPENAI_API_KEY="<open_ai_api_key>"
  export WEB_LOGIN_PASSWORD="<password to access the streamlit app or ChatBot>"
  ```

- Optional environment variables that you may alter in _setup

  ```
  export CB_HOME="<the home directory of Couchbase>"
  export CB_BUCKET=vectordemos
  export CB_SCOPE=langchain
  export CB_COLLECTION=webrag
  export CB_SEARCHINDEX=webrag_index
  ```

- Source the _setup file (we assume a bash shell)

  `. _setup`

- Set the executable mod for the following:

  `chmod +x check_couchbase.sh  check_openai.py  setup.sh`

- Verify connectivity and authentication to your Couchbase server

  `./check_couchbase.sh`

- Verify connectivity and authentication to OpenAI

  `./check_openai.py`

- Setup the Couchbase infrastructure (bucket, scope, collection and a search vector index) via the bash script

  `./setup.sh`

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
can run `./setup.sh` again if the bucket already exists you will get an option to flush all the data in your bucket.

