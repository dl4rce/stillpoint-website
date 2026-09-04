# Stillpoint website

Static site for **[Stillpoint](https://stillpointlab.dev)** — the open-source lab of
4rce.com working on persistent standing-place restore for hybrid attention models.

Live at **[stillpointlab.dev](https://stillpointlab.dev)**, served by GitHub Pages from
`main`. No build step: plain HTML, one self-hosted font, no JavaScript dependencies,
no trackers.

| File | Role |
|------|------|
| `index.html` | Landing page — the footprints-vs-standing-place metaphor, measured PIN-0001 results, how the pieces fit together |
| `whitepapers.html` | Index of living research papers and their validation status |
| `whitepaper.html` | PIN-0001 standing-place restore paper and measured result table |
| `pin-0005-ppas-plus.html` | PIN-0005 P-PAS+ paper: upstream credit, adaptation, lab setup, gates, results and run history |
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
run. Published evidence currently includes the PIN-0001 hard suite of 2026-08-21
(12/12 pass) and the PIN-0005 CT112 P-PAS+ validation of 2026-09-04. The PIN-0005
candidate passed all gates and 40/40 repeated workloads; its paired performance figures
are explicitly identified as preliminary two-repetition medians for one specific
mixed-pressure scenario. No projections or illustrative benchmarks are published.

The engineering behind those numbers — the LMCache patch, its explainer, and the
verification suite — lives in the `dl4rce/stillpoint` repository, which is not yet
public. Links to it from the site will resolve once it is published.

## Licence

Site content © 4rce.com Digital Technologies GmbH. Press Start 2P is licensed under
the SIL Open Font License 1.1 (see `fonts/OFL.txt`).
