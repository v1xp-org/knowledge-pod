# ============================================================================
# Knowledge Pod — Lightweight Scientific Research Workspace
# ============================================================================

# ─── Builder: uv ────────────────────────────────────────────────────────────
FROM ghcr.io/astral-sh/uv:latest AS uv

# ─── Builder: Neovim (pre-built binary) ────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS nvim-builder

USER root
ARG TARGETARCH

RUN NVIM_ARCH="${TARGETARCH}" \
 && if [ "$NVIM_ARCH" = "amd64" ]; then NVIM_ARCH="x86_64"; fi \
 && curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
 && tar xf nvim.tar.gz \
 && mv nvim-linux-${NVIM_ARCH} /usr/local/nvim \
 && rm nvim.tar.gz

# ─── Builder: CLI tools ────────────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS cli-builder

USER root
ARG TARGETARCH

# Crush (pre-built .deb — fetch latest version dynamically)
RUN CRUSH_VERSION=$(curl -fsSL https://api.github.com/repos/charmbracelet/crush/releases/latest | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//') \
 && curl -Lo crush.deb "https://github.com/charmbracelet/crush/releases/download/v${CRUSH_VERSION}/crush_${CRUSH_VERSION}_${TARGETARCH}.deb" \
 && dpkg-deb -x crush.deb /tmp/crush \
 && cp /tmp/crush/usr/bin/crush /usr/local/bin/crush \
 && rm -rf crush.deb /tmp/crush

# lazygit (pre-built binary — fetch latest version dynamically)
RUN LAZYGIT_ARCH="${TARGETARCH}" \
 && if [ "$LAZYGIT_ARCH" = "amd64" ]; then LAZYGIT_ARCH="x86_64"; fi \
 && LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//') \
 && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${LAZYGIT_ARCH}.tar.gz" \
 && tar xf lazygit.tar.gz lazygit \
 && install lazygit /usr/local/bin/ \
 && rm -f lazygit lazygit.tar.gz

# act (pre-built binary — fetch latest version dynamically)
RUN ACT_ARCH="${TARGETARCH}" \
 && if [ "$ACT_ARCH" = "amd64" ]; then ACT_ARCH="x86_64"; fi \
 && ACT_VERSION=$(curl -fsSL https://api.github.com/repos/nektos/act/releases/latest | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//') \
 && curl -Lo act.tar.gz "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz" \
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
   texlive-latex-base texlive-fonts-recommended \
   latexmk pandoc \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Builder: PDF tools venv ───────────────────────────────────────────────
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS pdf-builder

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   build-essential libffi-dev libssl-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

RUN uv venv --python 3.12 /opt/venvs/pdf-tools \
 && uv pip install --python /opt/venvs/pdf-tools/bin/python \
   pymupdf pdfplumber pypdf pikepdf

# ============================================================================
# FINAL STAGE — Assemble all artifacts
# ============================================================================
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

# ── System packages ────────────────────────────────────────────────────────
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y install --no-install-recommends \
   tmux curl git stow ca-certificates lsb-release \
   fzf ripgrep fd-find \
   poppler-utils imagemagick \
   sqlite3 libsqlite3-dev \
   libfontconfig1 libfreetype6 libgd3 libxrender1 libx11-6 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── COPY: Neovim (pre-built) ──────────────────────────────────────────────
COPY --from=nvim-builder /usr/local/nvim /usr/local/nvim
RUN ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim

# ── COPY: CLI tools ───────────────────────────────────────────────────────
COPY --from=cli-builder /usr/local/bin/crush    /usr/local/bin/crush
COPY --from=cli-builder /usr/local/bin/lazygit  /usr/local/bin/lazygit
COPY --from=cli-builder /usr/local/bin/act      /usr/local/bin/act
COPY --from=cli-builder /usr/bin/docker         /usr/bin/docker
COPY --from=cli-builder /usr/libexec/docker/cli-plugins/ /usr/libexec/docker/cli-plugins/

# ── COPY: LaTeX + Pandoc ──────────────────────────────────────────────────
COPY --from=latex-builder /usr/share/texlive/ /usr/share/texlive/
COPY --from=latex-builder /usr/share/texmf/   /usr/share/texmf/
COPY --from=latex-builder /usr/bin/latexmk    /usr/bin/latexmk
COPY --from=latex-builder /usr/bin/pandoc     /usr/bin/pandoc

# ── COPY: PDF tools venv ──────────────────────────────────────────────────
COPY --from=pdf-builder /opt/venvs/pdf-tools/ /opt/venvs/pdf-tools/

# ── Node.js + Zotero CLI ──────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g zotero-cli \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── uv + graphify ─────────────────────────────────────────────────────────
COPY --from=uv /uv /uvx /usr/local/bin/
RUN uv tool install graphifyy \
 && /root/.local/bin/graphify install opencode

# ── Venv helper ───────────────────────────────────────────────────────────
RUN echo '#!/bin/bash\nsource /opt/venvs/pdf-tools/bin/activate' \
      > /usr/local/bin/activate-pdf-tools \
 && chmod +x /usr/local/bin/activate-pdf-tools

# ── User setup ────────────────────────────────────────────────────────────
RUN groupadd -f docker && usermod -aG docker vscode \
 && mkdir -p /home/vscode && chown vscode:vscode /home/vscode \
 && chmod 755 /root && git init /root

USER vscode
RUN git config --global user.name "vscode" && git config --global user.email "vscode@devcontainer.local"

ENV PATH="/home/vscode/.local/bin:${PATH}"
