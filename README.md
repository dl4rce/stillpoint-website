# Stillpoint website

Static site for **[Stillpoint](https://stillpointlab.dev)** — the open-source lab of
[4rce.com](https://4rce.com) working on persistent standing-place restore for hybrid
attention models.

Live at **[stillpointlab.dev](https://stillpointlab.dev)**, served by GitHub Pages from
`main`. No build step: plain HTML, one self-hosted font, no JavaScript dependencies,
no trackers.

| File | Role |
|------|------|
| `index.html` | Landing page — the footprints-vs-standing-place metaphor, measured PIN-0001 results, how the pieces fit together |
| `whitepaper.html` | Whitepaper outline and the PIN-0001 result table |
| `imprint.html` | Impressum (§ 5 TMG) and privacy statement |
| `fonts/` | Press Start 2P (OFL 1.1), used for the logo only |
| `CNAME` | Custom-domain record for GitHub Pages |

## Preview locally

```bash
python3 -m http.server 8765
```

Then open http://localhost:8765/

## Numbers on this site

Every figure published here is measured on the pin hardware and traceable to a named
run — currently the PIN-0001 hard suite of 2026-08-21 (12/12 pass). No projections,
no illustrative benchmarks. If a number is not measured, it does not go on the page.

The engineering behind those numbers — the LMCache patch, its explainer, and the
verification suite — lives in [`dl4rce/stillpoint`](https://github.com/dl4rce/stillpoint),
not here.

## Security

- `.gitleaks.toml` — secret-scanning config for this repo
- pre-commit hook — `gitleaks` on staged files
- CI — `.github/workflows/gitleaks.yml` on every push and pull request
- Dependabot — security-only updates for GitHub Actions

## Licence

Site content © 4rce.com Digital Technologies GmbH. Press Start 2P is licensed under
the SIL Open Font License 1.1 (see `fonts/OFL.txt`).
