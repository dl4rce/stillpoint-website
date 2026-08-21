# Stillpoint website

Static site for **[Stillpoint](https://stillpointlab.dev)** — the open-source lab of
4rce.com working on persistent standing-place restore for hybrid attention models.

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

Then open <http://localhost:8765/>. There is nothing to build or install — the files
are served exactly as they are deployed.

## Numbers on this site

Every figure published here is measured on the pin hardware and traceable to a named
run — currently the PIN-0001 hard suite of 2026-08-21 (12/12 pass). No projections,
no illustrative benchmarks. If a number is not measured, it does not go on the page.

The engineering behind those numbers — the LMCache patch, its explainer, and the
verification suite — lives in the `dl4rce/stillpoint` repository, which is not yet
public. Links to it from the site will resolve once it is published.

## Security

- `.gitleaks.toml` — secret-scanning config, run in CI on every push and pull request
  via `.github/workflows/gitleaks.yml`
- Dependabot — security-only updates for GitHub Actions

Contributors are encouraged to run `gitleaks` locally before committing; a pre-commit
hook is not shipped in this repository, since Git does not distribute hooks on clone.

## Licence

Site content © 4rce.com Digital Technologies GmbH. Press Start 2P is licensed under
the SIL Open Font License 1.1 (see `fonts/OFL.txt`).
