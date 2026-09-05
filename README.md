# Stillpoint website

Static site for **[Stillpoint](https://stillpointlab.dev)** — the open-source lab of
4rce.com working on persistent standing-place restore for hybrid attention models.

Live at **[stillpointlab.dev](https://stillpointlab.dev)**, served by GitHub Pages from
`main` in the separate `dl4rce/stillpoint-website` repository. Plain HTML, CSS and
JavaScript; no dependencies, package manifest, build step, external fonts or trackers.
Do not run npm from this repository or its parent to build the site.

## Site architecture

- `index.html`: Living Context landing page, interactive explanatory sculpture,
  matched PIN-0001 restart evidence, hybrid-state explanation, Flaiwheel and research pins.
- `site.css`: shared graphite/cyan design system, responsive navigation and layouts,
  accessible focus states, paper-table scrolling, CSS 3D sculpture and motion controls.
- `site.js`: progressive enhancement for mobile navigation, explicit lifecycle steps,
  illustrative prefix-size control, opt-in motion and visibility/offscreen gating.
- `flaiwheel.css`: retained research-memory sculpture styles, harmonized by `site.css`.
- `whitepapers.html`: living-paper index and validation status.
- `whitepaper.html`: PIN-0001 report and full measured result table.
- `pin-0005-ppas-plus.html`: PIN-0005 P-PAS+ report, upstream credit, methods and run history.
- `imprint.html`: legal imprint and privacy statement; legal text retained.
- `pdf/` and `papers/`: published PDFs, checksum manifest and typeset sources;
  unchanged by the visual redesign.
- `fonts/`: retained historical Press Start 2P asset and OFL licence. The redesigned
  interface uses system typography; legacy paper styles retain a local font declaration.
- `CNAME`: custom-domain record for GitHub Pages.

The four secondary pages retain their page-specific scientific layout styles and load
`site.css` afterwards for a consistent shell. Scientific tables remain HTML tables in
keyboard-focusable horizontal-scroll regions. Every page has a skip link and main landmark.
Navigation and published evidence remain usable without JavaScript.

## Living Context interaction

The hero is an **illustrative diagram, not a live backend or a benchmark**. Select,
Compile, Persist, Restart and Restore are user-selected explanatory scenes. During
Select/Compile, a prefix-size control changes full-attention KV while the recurrent
core keeps its shape. Persist writes both symbolic components to a disk checkpoint;
Restart removes the running engine while retaining that checkpoint. Restore illustrates
loading the same exact prefix into a new engine. Layer counts and geometry do not
represent measured bytes, model layers or hardware capacity.

Motion is off by default. A page-level button enables gentle motion; system reduced-motion
preference overrides it. The Flaiwheel sculpture only animates while in view and the
page is visible. No ambient starfield, timer, autoplay sequence or network inference call.
Without JavaScript the hero shows a labeled persisted-state diagram.

Context selection, freezing, graceful eviction and per-tenant salted keys remain
roadmap goals, not completed production capabilities. Flaiwheel retrieves Git-backed
documentation; it does not write model KV state.

## Preview locally

Run from this repository:

```bash
python3 -m http.server 8765
```

Then open <http://localhost:8765/>. The files are served exactly as deployed.
Use `node --check site.js` for JavaScript syntax and `git diff --check` for whitespace;
validate HTML links/anchors and JSON-LD, then check desktop/mobile, keyboard navigation,
all five diagram steps and reduced motion in a browser before publishing. No npm needed.

## Numbers on this site

The homepage comparison uses the matched **2026-08-22 PIN-0001 patch rev 2** run:
26k context, 27.41 s cold / 3.60 s restored end-to-end wall (displayed as 27.4 / 3.6),
7.6× ratio, 98.7% cache hit and a 12/12 hard-suite pass. Static bars share one zero
baseline and use those published unrounded wall values. Wall includes answer generation,
not engine startup. The test was a full vLLM process restart, not a host reboot.
Historical rev 1 values remain explicitly labeled in the scientific paper, never mixed
into the homepage comparison. The cold negative control is not a tenant-isolation proof.

PIN-0005 CT112 validation of 2026-09-04 passed all candidate gates and 40/40 repeated
workloads. Paired performance figures are preliminary two-repetition medians for one
specific mixed-pressure scenario, not universal gains. No invented metrics or projections.

The public PIN-0001 patch, explainer and verification steps are available in
[dl4rce/lmcache-hybrid-gdn-restore-fix](https://github.com/dl4rce/lmcache-hybrid-gdn-restore-fix).
The separate engineering repository retains additional evidence pending disclosure review.

## Backups and publishing

Before the redesign, each modified original received an identical timestamped
`.20260905T115800+0200.pre-living-context.backup` copy, verified with SHA-256.
The suffix identifies the pre-Living-Context fallback. These backups are ignored by Git;
do not publish them as site assets. Review changes before committing or pushing.

## Licence

Site content © 4rce.com Digital Technologies GmbH. The retained Press Start 2P font is
licensed under the SIL Open Font License 1.1 (see `fonts/OFL.txt`).
