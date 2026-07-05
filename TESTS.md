# Knowledge Pod — Verification Instructions

Run these commands inside the knowledge-pod to verify everything works.

## 1. Core Tools

```bash
# Check all core tools are installed
nvim --version | head -1
uv --version
crush --version
lazygit --version
act --version
docker --version
docker compose version
node --version
graphify --version
git --version
```

## 2. Scientific Tools

```bash
# LaTeX
pdflatex --version | head -1
latexmk --version | head -1

# Pandoc
pandoc --version | head -1

# Poppler (PDF extraction)
pdftotext -v 2>&1 | head -1
pdfinfo -v 2>&1 | head -1

# ImageMagick
convert --version | head -1

# SQLite
sqlite3 --version
```

## 3. PDF Python Tools

```bash
# Activate the PDF tools venv
source /opt/venvs/pdf-tools/bin/activate

# Verify all PDF libraries import correctly
python -c "
import fitz; print(f'PyMuPDF {fitz.version}')
import pdfplumber; print(f'pdfplumber {pdfplumber.__version__}')
import pypdf; print(f'pypdf {pypdf.__version__}')
import pikepdf; print(f'pikepdf {pikepdf.__version__}')
print('All PDF tools OK')
"

deactivate
```

## 4. PDF Processing End-to-End

```bash
# Create a test PDF
cat > /tmp/test.tex << 'EOF'
\documentclass{article}
\begin{document}
Hello from Knowledge Pod! This is a test document.
\end{document}
EOF

cd /tmp && pdflatex -interaction=nonstopmode test.tex

# Verify CLI extraction
pdftotext test.pdf - | grep -q "Hello from Knowledge Pod" && echo "pdftotext: OK" || echo "pdftotext: FAIL"
pdfinfo test.pdf | grep -q "Pages" && echo "pdfinfo: OK" || echo "pdfinfo: FAIL"

# Verify Python extraction
source /opt/venvs/pdf-tools/bin/activate
python -c "
import fitz
doc = fitz.open('/tmp/test.pdf')
text = doc[0].get_text()
assert 'Hello from Knowledge Pod' in text, 'PyMuPDF extraction failed'
print('PyMuPDF extraction: OK')
"
deactivate

rm -f /tmp/test.{tex,pdf,aux,log}
```

## 5. Graphify

```bash
# Create a minimal test project
mkdir -p /tmp/test-project && cd /tmp/test-project
cat > main.py << 'EOF'
def hello():
    return "world"
EOF

# Generate knowledge graph
graphify update .

# Verify graph was created
test -f graphify-out/graph.json && echo "Graphify: OK" || echo "Graphify: FAIL"

# Clean up
cd /workspaces && rm -rf /tmp/test-project
```

## 6. Docker (Docker-outside-of-Docker)

```bash
# Test Docker socket access
docker ps >/dev/null 2>&1 && echo "Docker socket: OK" || echo "Docker socket: FAIL"

# Test image pull (small image)
docker pull alpine:3.19 >/dev/null 2>&1 && echo "Docker pull: OK" || echo "Docker pull: FAIL"

# Test container run
docker run --rm alpine:3.19 echo "Docker run: OK"

# Clean up
docker rmi alpine:3.19 >/dev/null 2>&1
```

## 7. Git + LazyGit

```bash
# Verify git config
git config --global user.name >/dev/null && echo "Git user: OK" || echo "Git user: NOT SET"
git config --global user.email >/dev/null && echo "Git email: OK" || echo "Git email: NOT SET"

# LazyGit just needs to launch (check binary exists)
which lazygit >/dev/null && echo "LazyGit: OK" || echo "LazyGit: FAIL"
```

## 8. Quick Summary Script

Run this for a one-shot status check:

```bash
echo "=== Knowledge Pod Status ==="
echo ""
echo "Core:"
for cmd in nvim uv crush lazygit act docker node graphify; do
  printf "  %-12s" "$cmd"
  command -v $cmd >/dev/null 2>&1 && echo "OK" || echo "MISSING"
done
echo ""
echo "Scientific:"
for cmd in pdflatex latexmk pandoc pdftotext pdfinfo convert sqlite3; do
  printf "  %-12s" "$cmd"
  command -v $cmd >/dev/null 2>&1 && echo "OK" || echo "MISSING"
done
echo ""
echo "PDF Python:"
source /opt/venvs/pdf-tools/bin/activate
python -c "
for mod in ['fitz', 'pdfplumber', 'pypdf', 'pikepdf']:
    try:
        __import__(mod)
        print(f'  {mod:<12}OK')
    except:
        print(f'  {mod:<12}FAIL')
"
deactivate
echo ""
echo "=== Done ==="
```

## Expected Results

All checks should print `OK`. If any show `MISSING` or `FAIL`, the corresponding tool wasn't installed correctly in the Dockerfile.
