---
name: marp
description: "Markdown-to-slide-deck conversion (HTML/PDF/PPTX) via the bundled marp-cli."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [presentation, slides, markdown, marp]
    related_skills: [infra-architecture-diagram, design-md, popular-web-designs]
---

# Marp Skill

Convert Marp-flavored Markdown into slide decks (HTML, PDF, PPTX) using `@marp-team/marp-cli` run through the agent's own bundled Node runtime. No separate service call needed.

## When to use

- The user wants a slide deck / presentation generated from Markdown content.

## Usage

Write the Markdown to a file (front matter must include `marp: true`), then convert:

```bash
export PATH=/root/.hermes/node/bin:$PATH
cat > /tmp/slides.md <<'EOF'
---
marp: true
theme: default
---

# Title Slide

---

# Second Slide

- point one
- point two
EOF

marp /tmp/slides.md -o /tmp/slides.html
```

- **HTML output**: ✅ Works out of the box (no browser needed)
- **PDF output**: ✅ Now working (Chrome installed 2026-07-29)
- **PPTX output**: ✅ Now working (Chrome installed 2026-07-29)

All export formats are now fully functional!

## Current Status (2026-07-29)

- **Installation**: ✅ Successfully installed via npm
- **Version**: `@marp-team/marp-cli v4.5.0` with `@marp-team/marp-core v4.4.0`
- **Node.js**: ✅ v22.22.1 installed in Hermes pod
- **Browser**: ✅ Google Chrome 150.0.7871.186 installed (for PDF/PPTX)
- **HTML Conversion**: ✅ Working perfectly (tested with sample presentation)
- **PDF Conversion**: ✅ Now working (Chrome installed)
- **PPTX Conversion**: ✅ Now working (Chrome installed)
- **Test Files**: Created `/tmp/test-presentation.md` and successfully generated HTML, PDF, and PPTX outputs
## Notes

- `node`/`npm`/`marp` are NOT on the default shell `$PATH` — always prefix commands with `export PATH=/root/.hermes/node/bin:$PATH` first.
- Do not try to register this as an MCP server — `marp-cli` is a one-shot CLI, not an MCP-protocol server; `hermes mcp add --command` expects a persistent process speaking MCP JSON-RPC over stdio, which marp-cli does not do.
- The `marp-server` HTTP service in the `ai-tools` namespace exists for non-Hermes consumers (e.g. direct team/browser access) — Hermes itself doesn't need to call it.
