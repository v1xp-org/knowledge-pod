# Knowledge Pod

A DevPod-based scientific research workspace. Multi-stage Docker build with Neovim, Crush, LaTeX, PDF tools, and Zotero integration — designed to be lean by default with optional heavy extras.

## Quick Start

```bash
# Docker
docker build -t knowledge-pod .devcontainer/
docker run -it -v /var/run/docker.sock:/var/run/docker.sock knowledge-pod

# DevPod
devpod provider use docker
devpod up github.com/yourorg/knowledge-pod
```

## What's Included

### Core

| Tool | Purpose |
|------|---------|
| **Neovim** (stable, built from source) | Editor |
| **uv** (Astral) | Fast Python package/project manager |
| **Crush** | AI coding assistant |
| **lazygit** | Git TUI |
| **act** | Local GitHub Actions runner |
| **Docker CLI** | Container management |
| **graphify** | Knowledge graph generation for codebases |

### Scientific

| Tool | Purpose |
|------|---------|
| **LaTeX** | TeX Live (base + extras + science + fonts) |
| **latexmk** | LaTeX build automation |
| **Pandoc** | Universal document converter |
| **Poppler** | PDF text extraction (`pdftotext`, `pdfinfo`) |
| **ImageMagick** | Figure processing |
| **SQLite3** | Local structured data |

### PDF Processing

| Tool | Purpose |
|------|---------|
| **PyMuPDF** | Fast PDF parsing |
| **pdfplumber** | Table-aware PDF extraction |
| **pypdf** | PDF manipulation |
| **marker-pdf** | PDF-to-Markdown with layout understanding |
| **unstructured** | Document ingestion for RAG pipelines |
| **pikepdf** | Low-level PDF editing |

Installed in an isolated venv at `/opt/venvs/pdf-tools` (Python 3.12).

### Reference Management

| Tool | Purpose |
|------|---------|
| **zotero-cli** (Node) | CLI access to Zotero libraries |
| **pyzotero** | Python Zotero API wrapper for LLM pipelines |
| **Better BibTeX** | BibTeX export (install plugin on host) |

## Usage

### Crush

```bash
# Start Crush in your project
crush

# Or use with a specific model
crush --model anthropic/claude-sonnet-4-20250514
```

### Zotero

```bash
# Get your API key (free):
#   1. Go to https://www.zotero.org/settings/keys
#   2. Click "Create new private key"
#   3. Give it a name (e.g., "Knowledge Pod")
#   4. Set access level to "Allow library access"
#   5. Copy the key

# Your User ID is the number in https://www.zotero.org/users/YOUR_USER_ID
export ZOTERO_API_KEY="your-key"
export ZOTERO_USER_ID="your-user-id"

# List collections
zotero-cli collections

# List items in a collection
zotero-cli items --collection <collectionKey>

# Export as BibTeX
zotero-cli export --format bibtex > references.bib
```

### PDF Tools

```bash
# CLI extraction
pdftotext paper.pdf paper.txt
pdfinfo paper.pdf

# Python extraction
source activate-pdf-tools
python -c "
import fitz
doc = fitz.open('paper.pdf')
for page in doc:
    print(page.get_text())
"

# PDF to Markdown (layout-aware)
marker_single paper.pdf --output_dir ./converted/
```

### Graphify

```bash
# Generate a knowledge graph of your codebase
graphify .

# Query the graph
graphify query "How is authentication handled?"

# Find relationships between concepts
graphify path "UserService" "AuthMiddleware"
```

## Optional Add-ons

These are not included in the base image to keep it lean. Install inside the container as needed.

### JupyterLab

```bash
uv tool install jupyterlab
jupyterlab --no-browser --port 8888
```

### LlamaIndex (RAG)

```bash
uv venv --python 3.12 /opt/venvs/llamaindex
uv pip install --python /opt/venvs/llamaindex/bin/python \
  llama-index-core llama-index-llms-ollama llama-index-embeddings-ollama \
  llama-index-readers-file llama-index-vector-stores-chroma pyzotero

# Usage
source /opt/venvs/llamaindex/bin/activate
python -c "
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
docs = SimpleDirectoryReader('./papers').load_data()
index = VectorStoreIndex.from_documents(docs)
print(index.as_query_engine().query('Main findings?'))
"
```

### Khoj (Research Assistant)

```bash
uv venv --python 3.12 /opt/venvs/khoj
uv pip install --python /opt/venvs/khoj/bin/python khoj
/opt/venvs/khoj/bin/khoj --host 0.0.0.0 --port 8600
```

### Ollama (Local LLMs)

```bash
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llama3
```

### LaTeX Packages

```dockerfile
# In the Dockerfile, after the apt-get install block:
RUN tlmgr install <package-name>
```

## Configuration

### devcontainer.json

```json
{
  "image": "ghcr.io/yourorg/knowledge-pod:latest",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind",
    "source=${localEnv:HOME}/Zotero,target=/home/vscode/Zotero,type=bind,consistency=cached,readonly"
  ],
  "remoteUser": "vscode"
}
```

## Build

```bash
# Local build
docker build -t knowledge-pod .devcontainer/

# Multi-arch (via GitHub Actions)
# Push to .devcontainer/ on main — builds amd64 + arm64 to GHCR
```

## Directory Layout

```
knowledge-pod/
├── .devcontainer/
│   ├── Dockerfile           # Multi-stage build (8 builders + final)
│   ├── devcontainer.json    # DevPod / VS Code config
│   └── .dockerignore
├── .github/workflows/
│   └── build-image.yml      # Multi-arch GHCR build
└── README.md
```

## Image Architecture

```
Builder stages (discarded):
  uv                    Astral package manager
  nvim-builder          Neovim from source
  cli-builder           crush, lazygit, act, docker-cli
  latex-builder         TeX Live + latexmk + pandoc
  pdf-builder           PDF processing Python libraries
  python-tools-builder  uv tools (graphify)

Final stage:
  Ubuntu 24.04 + system deps + LaTeX runtime libs
  + COPY artifacts from each builder
  + Node.js + zotero-cli (installed directly)
  + graphify install crush
```
