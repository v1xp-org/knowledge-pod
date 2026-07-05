# Knowledge Pod

A DevPod-based scientific research workspace. Forked from [devpods-builds](../devpods-builds/) and extended with AI, PDF, and reference-management tooling.

## What's Inside

### Core (inherited from devpods-builds)

| Tool | Purpose |
|------|---------|
| **Neovim** (stable, from source) | Editor |
| **uv** (Astral) | Fast Python package/project manager |
| **opencode** (Crush / Charm) | AI coding assistant |
| **lazygit** | Git TUI |
| **act** | Local GitHub Actions runner |
| **Docker CLI** | Container management |
| **graphify** | Knowledge graph generation for codebases |

### Scientific Research

| Tool | Purpose |
|------|---------|
| **JupyterLab** | Interactive notebooks (Python kernel) |
| **LaTeX** | Full TeX Live (texlive-latex-base + extras + science + fonts) |
| **latexmk** | LaTeX build automation |
| **Pandoc** | Universal document converter |
| **Poppler** | PDF text extraction (`pdftotext`, `pdfinfo`, etc.) |
| **ImageMagick** | Figure processing |
| **SQLite3** | Local structured data |

### AI / LLM Tooling

| Tool | Purpose |
|------|---------|
| **graphify** | Knowledge graph generation for codebases |
| **pyzotero** | Zotero API wrapper — bridge into LLM pipelines |

> **Optional additions:** LlamaIndex, Khoj, Ollama, ChromaDB, Qdrant
> can be installed in the container after build. See [Customization](#customization).

### PDF & Document Processing

| Tool | Purpose |
|------|---------|
| **PyMuPDF** | Fast PDF parsing |
| **pdfplumber** | Table-aware PDF extraction |
| **pypdf** | PDF manipulation |
| **marker-pdf** | PDF-to-Markdown with layout understanding |
| **unstructured** | Document ingestion for RAG pipelines |
| **pikepdf** | Low-level PDF editing |

### Reference Management

| Tool | Purpose |
|------|---------|
| **zotero-cli** (Node) | CLI access to Zotero libraries (`zotero-cli` command) |
| **pyzotero** | Python Zotero API wrapper — fetch papers/metadata for LlamaIndex |
| **Better BibTeX** | BibTeX export (install the Zotero plugin on your host) |

## Quick Start

```bash
# Build the image
cd knowledge-pod
docker build -t knowledge-pod .devcontainer/

# Or use DevPod
devpod provider use docker
devpod up github.com/yourorg/knowledge-pod
```

## Port Forwarding

| Port | Service |
|------|---------|
| 8888 | JupyterLab |

## Directory Layout

```
knowledge-pod/
├── .devcontainer/
│   ├── Dockerfile           # Multi-stage build
│   ├── devcontainer.json    # DevPod / VS Code config
│   └── .dockerignore
├── .github/workflows/
│   └── build-image.yml      # Multi-arch GHCR build
└── README.md
```

## Python Environments

| Venv | Contents |
|------|----------|
| `/opt/venvs/pdf-tools` | PDF processing libraries |

System Python also has `jupyterlab`, `notebook`, and `graphify` installed as uv tools (available globally).

## Using JupyterLab

```bash
# Start JupyterLab
jupyterlab --no-browser --port 8888

# Or open in VS Code via the Ports panel
```

## Using Zotero

```bash
# List collections (requires ZOTERO_API_KEY and ZOTERO_USER_ID env vars)
export ZOTERO_API_KEY="your-key"
export ZOTERO_USER_ID="your-user-id"

zotero-cli collections
zotero-cli items --collection <collectionKey>
zotero-cli export --format bibtex > references.bib
```

## Using PDF Tools

```bash
# Extract text from a PDF
pdftotext paper.pdf paper.txt

# Get PDF metadata
pdfinfo paper.pdf

# Python-based extraction
source /opt/venvs/pdf-tools/bin/activate
python -c "
import fitz
doc = fitz.open('paper.pdf')
for page in doc:
    print(page.get_text())
"

# Convert PDF to Markdown (layout-aware)
marker_single paper.pdf --output_dir ./converted/
```

## Customization

### Add more LaTeX packages

```dockerfile
# In the Dockerfile, after the apt-get install block:
RUN tlmgr install <package-name>
```

### Install LlamaIndex for RAG

```bash
# Inside the container
uv venv --python 3.12 /opt/venvs/llamaindex
uv pip install --python /opt/venvs/llamaindex/bin/python \
  llama-index-core llama-index-llms-ollama llama-index-embeddings-ollama \
  llama-index-readers-file llama-index-vector-stores-chroma pyzotero
```

### Install Khoj (research assistant)

```bash
uv venv --python 3.12 /opt/venvs/khoj
uv pip install --python /opt/venvs/khoj/bin/python khoj
# Start: /opt/venvs/khoj/bin/khoj --host 0.0.0.0 --port 8600
```

### Add Ollama for local LLMs

```bash
# Install Ollama in the container
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llama3
```

### Mount your Zotero library

Add to `devcontainer.json` mounts:

```json
"source=${localEnv:HOME}/Zotero,target=/home/vscode/Zotero,type=bind,consistency=cached,readonly"
```
