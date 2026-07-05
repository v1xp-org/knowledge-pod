#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }
warn() { ((WARN++)); echo "  ! $1"; }

echo "=== Knowledge Pod Verification ==="
echo ""

# --- Core Tools ---
echo "Core tools:"
for cmd in nvim uv crush lazygit act docker node graphify git; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd"
  else
    fail "$cmd not found"
  fi
done
echo ""

# --- Scientific Tools ---
echo "Scientific tools:"
for cmd in pdflatex latexmk pandoc pdftotext pdfinfo convert sqlite3; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd"
  else
    fail "$cmd not found"
  fi
done
echo ""

# --- PDF Python Tools ---
echo "PDF Python tools:"
if [ -d /opt/venvs/pdf-tools ]; then
  source /opt/venvs/pdf-tools/bin/activate
  for mod in fitz pdfplumber pypdf pikepdf; do
    if python -c "import $mod" 2>/dev/null; then
      pass "$mod"
    else
      fail "$mod import failed"
    fi
  done
  deactivate
else
  fail "PDF venv not found at /opt/venvs/pdf-tools"
fi
echo ""

# --- PDF End-to-End ---
echo "PDF processing:"
cd /tmp
cat > test-kp.tex << 'TEXEOF'
\documentclass{article}
\begin{document}
Hello from Knowledge Pod verification!
\end{document}
TEXEOF

if pdflatex -interaction=nonstopmode test-kp.tex &>/dev/null; then
  pass "pdflatex compiled"
else
  fail "pdflatex compilation failed"
fi

if pdftotext test-kp.pdf - 2>/dev/null | grep -q "Hello from Knowledge Pod"; then
  pass "pdftotext extraction"
else
  fail "pdftotext extraction failed"
fi

if source /opt/venvs/pdf-tools/bin/activate && python -c "
import fitz
doc = fitz.open('/tmp/test-kp.pdf')
assert 'Hello from Knowledge Pod' in doc[0].get_text()
" 2>/dev/null; then
  pass "PyMuPDF extraction"
  deactivate
else
  fail "PyMuPDF extraction failed"
fi

rm -f /tmp/test-kp.{tex,pdf,aux,log}
echo ""

# --- Graphify ---
echo "Graphify:"
mkdir -p /tmp/test-gproj
cat > /tmp/test-gproj/main.py << 'PYEOF'
def hello():
    return "world"
PYEOF

if (cd /tmp/test-gproj && graphify update . &>/dev/null && test -f graphify-out/graph.json); then
  pass "graphify graph generation"
else
  warn "graphify generation (non-critical)"
fi
rm -rf /tmp/test-gproj
echo ""

# --- Docker ---
echo "Docker:"
if docker ps &>/dev/null; then
  pass "Docker socket access"
else
  warn "Docker socket not available (host-only)"
fi
echo ""

# --- Git ---
echo "Git config:"
if git config --global user.name &>/dev/null; then
  pass "user.name set"
else
  warn "user.name not set"
fi
if git config --global user.email &>/dev/null; then
  pass "user.email set"
else
  warn "user.email not set"
fi
echo ""

# --- Summary ---
echo "==========================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo "==========================="

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAILED"
  exit 1
else
  echo "RESULT: PASSED"
  exit 0
fi
