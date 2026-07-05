# ============================================================================
# Knowledge Pod — Multi-stage Scientific Research Workspace
# ============================================================================
# ─── Builder: uv ────────────────────────────────────────────────────────────
FROM ghcr.io/astral-sh/uv:latest AS uv

# ─── Builder: Neovim ────────────────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS nvim-builder

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   git cmake ninja-build gettext libtool libtool-bin autoconf automake \
   g++ pkg-config unzip curl build-essential systemtap-sdt-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ARG NVIM_VERSION=stable
RUN NVIM_TAG="${NVIM_VERSION}" \
 && if [ "$NVIM_TAG" = "stable" ]; then \
   NVIM_TAG=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
     | grep '"tag_name"' | cut -d '"' -f 4); \
 fi \
 && echo "Building Neovim $NVIM_TAG" \
 && git clone --depth 1 --branch "$NVIM_TAG" https://github.com/neovim/neovim /tmp/nvim \
 && cd /tmp/nvim \
 && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/usr/local \
 && make install \
 && rm -rf /tmp/nvim

# ─── Builder: CLI tools ────────────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS cli-builder

USER root

ARG TARGETARCH

# Crush (AI coding assistant)
RUN curl -fsSL https://opencode.ai/install | bash \
 && cp /root/.opencode/bin/opencode /usr/local/bin/crush

# lazygit
ARG LAZYGIT_VERSION=0.44.1
RUN LAZYGIT_ARCH="${TARGETARCH}" \
 && if [ "$LAZYGIT_ARCH" = "amd64" ]; then LAZYGIT_ARCH="x86_64"; fi \
 && curl -Lo lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
 && tar xf lazygit.tar.gz lazygit \
 && install lazygit /usr/local/bin/ \
 && rm -f lazygit lazygit.tar.gz

# act (GitHub Actions local runner)
ARG ACT_VERSION=0.2.89
RUN ACT_ARCH="${TARGETARCH}" \
 && if [ "$ACT_ARCH" = "amd64" ]; then ACT_ARCH="x86_64"; fi \
 && curl -Lo act.tar.gz \
      "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz" \
 && tar xf act.tar.gz act \
 && install act /usr/local/bin/ \
 && rm -f act act.tar.gz

# Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
   | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
   > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get -y install --no-install-recommends docker-ce-cli docker-compose-plugin \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Builder: LaTeX + Pandoc ────────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS latex-builder

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   texlive-latex-base texlive-latex-extra texlive-fonts-recommended \
   texlive-fonts-extra texlive-science texlive-bibtex-extra \
   latexmk \
   pandoc \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# ─── Builder: PDF tools venv ───────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS pdf-builder

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   build-essential libffi-dev libssl-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

RUN uv venv --python 3.12 /opt/venvs/pdf-tools

RUN uv pip install --python /opt/venvs/pdf-tools/bin/python \
   pymupdf \
   pdfplumber \
   pypdf \
   marker-pdf \
   unstructured \
   pikepdf

RUN find /opt/venvs/pdf-tools -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; \
    rm -rf /opt/venvs/pdf-tools/lib/python*/site-packages/pip /opt/venvs/pdf-tools/lib/python*/site-packages/setuptools

# ─── Builder: uv tools (jupyterlab, notebook) ──────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS python-tools-builder

USER root

COPY --from=uv /uv /uvx /usr/local/bin/

RUN uv tool install graphifyy \
 && uv tool install jupyterlab \
 && uv tool install notebook

# ============================================================================
# FINAL STAGE — Assemble all artifacts
# ============================================================================
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

# ── System packages (core + PDF + LaTeX runtime + image processing) ─────────
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   # Core
   tmux curl git stow ca-certificates lsb-release \
   fzf ripgrep fd-find \
   # PDF / document processing
   poppler-utils \
   # Image processing (for figures)
   imagemagick \
   # SQLite
   sqlite3 libsqlite3-dev \
   # LaTeX runtime deps (needed by copied texlive binaries)
   libfontconfig1 libfreetype6 libgd3 libxrender1 libx11-6 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── COPY: Neovim binaries ──────────────────────────────────────────────────
COPY --from=nvim-builder /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=nvim-builder /usr/local/lib/nvim /usr/local/lib/nvim
COPY --from=nvim-builder /usr/local/share/nvim /usr/local/share/nvim

# ── COPY: CLI tools (crush, lazygit, act, docker) ──────────────────────────
COPY --from=cli-builder /usr/local/bin/crush        /usr/local/bin/crush
COPY --from=cli-builder /usr/local/bin/lazygit   /usr/local/bin/lazygit
COPY --from=cli-builder /usr/local/bin/act       /usr/local/bin/act
COPY --from=cli-builder /usr/bin/docker          /usr/bin/docker
COPY --from=cli-builder /usr/libexec/docker/cli-plugins/ /usr/libexec/docker/cli-plugins/

# ── COPY: LaTeX + Pandoc ───────────────────────────────────────────────────
COPY --from=latex-builder /usr/share/texlive/    /usr/share/texlive/
COPY --from=latex-builder /usr/share/texmf/      /usr/share/texmf/
COPY --from=latex-builder /usr/bin/latexmk       /usr/bin/latexmk
COPY --from=latex-builder /usr/bin/pandoc        /usr/bin/pandoc

# ── COPY: Node.js + Zotero CLI ─────────────────────────────────────────────
# NodeSource paths vary; install directly in final stage for reliability.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g zotero-cli \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── COPY: Python venvs ─────────────────────────────────────────────────────
COPY --from=pdf-builder        /opt/venvs/pdf-tools/  /opt/venvs/pdf-tools/

# ── COPY: uv tools (jupyterlab, notebook, graphify) ────────────────────────
COPY --from=python-tools-builder /root/.local/   /home/vscode/.local/

# ── COPY: uv binary ────────────────────────────────────────────────────────
COPY --from=uv /uv /uvx /usr/local/bin/

# ── graphify install opencode (Crush skill) ─────────────────────────────────
RUN graphify install opencode

# ── Venv helper scripts ────────────────────────────────────────────────────
RUN echo '#!/bin/bash\nsource /opt/venvs/pdf-tools/bin/activate' \
      > /usr/local/bin/activate-pdf-tools \
 && chmod +x /usr/local/bin/activate-*

# ── User setup ─────────────────────────────────────────────────────────────
RUN groupadd -f docker && usermod -aG docker vscode \
 && mkdir -p /home/vscode && chown vscode:vscode /home/vscode \
 && chmod 755 /root && git init /root

USER vscode
RUN git config --global user.name "vscode" && git config --global user.email "vscode@devcontainer.local"
RUN nvim --headless +"set spelllang=en_us,pt_br" +qa 2>/dev/null || true

ENV PATH="/home/vscode/.local/bin:${PATH}"
