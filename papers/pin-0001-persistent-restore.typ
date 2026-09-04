#import "template.typ": stillpoint-paper

#let accent = rgb("167d8d")
#let abstract = [
  Persistent prefix caches for hybrid gated-delta-network models must restore both recurrent state and full-attention key/value pages. In LMCache 0.5.3 multiprocess mode, the full-attention group of a Qwen3.8 hybrid model was misclassified under vLLM 0.27.1's packed layout, causing only one of 25 kernel pages per 1,600-token chunk to be persisted. A second defect corrupted asynchronously copied host data because shared metadata addresses were mutated during pagewise transfer. We developed a four-file patch using geometry-aware page expansion and independent page-view metadata, then evaluated it on a dual-GPU Qwen3.8-27B serving stack. A 12-run hard suite buried random keys in 5k, 13k, and 26k contexts, fully restarted both vLLM and the LMCache server, restored from disk-backed L2, and required byte-exact key recovery. All 12 runs passed. External cache hit rates were 97.0–98.8%; end-to-end wall time improved by 2.6×–7.6× and time to first token by 5.0×–9.9× relative to matched cold prefills. A never-stored negative control achieved 0% external hit, excluding cross-namespace leakage. The result validates exact-prefix persistent restore for the declared hybrid configuration, not arbitrary position-independent reuse or universal hybrid-model portability.
]

#show: stillpoint-paper.with(
  pin: "PIN-0001",
  title: "Persistent LMCache Restore for Hybrid GDN Models",
  subtitle: "Root-cause analysis, geometry-correct transfer, and restart validation",
  version: "2.0",
  published: "22 August 2026",
  revised: "4 September 2026",
  status: "Green · 12/12 hard-suite pass",
  abstract: abstract,
  keywords: ("LMCache", "persistent KV cache", "hybrid GDN", "Qwen3.8", "vLLM", "restart restore", "TTFT"),
  canonical_url: "https://stillpointlab.dev/whitepaper.html",
  pdf_url: "https://stillpointlab.dev/pdf/pin-0001-persistent-restore.pdf",
)

= Executive summary
#table(
  columns: (30mm, 1fr), inset: 7pt, stroke: .45pt + rgb("c7cdd5"),
  [*Problem*], [Hybrid recurrent state appeared to restore, but the full-attention pages were incomplete or corrupted after a full process restart.],
  [*Contribution*], [A four-file LMCache 0.5.3 fix for hybrid full-attention page geometry and asynchronous metadata integrity.],
  [*Strongest result*], [At 26k context, restore reduced end-to-end wall time 7.6× and TTFT 9.9× versus a matched cold prefill.],
  [*Validation*], [12/12 hard-suite pass with byte-exact buried-key recovery and 97.0–98.8% external hit.],
  [*Current status*], [Green; patch revision 2 published and verified against a pristine wheel.],
  [*Key limitation*], [Exact-prefix restore only. Changed token sequences require recomputation, and portability beyond tested layouts is not established.],
)

= Problem statement
Hybrid GDN/full-attention models do not represent all context as a uniform, token-indexed KV sequence. Most layers carry a compact recurrent state, while full-attention layers retain conventional key/value pages. A persistent cache must serialize and restore both representations consistently. High cache-hit metrics alone are insufficient: recurrent objects can match while incomplete full-attention payloads silently produce fluent but wrong output.

The acceptance criterion was therefore semantic and operational. After a full vLLM and LMCache-server restart, a random key buried in a long exact prefix had to be reproduced character for character, with a high external cache hit and substantially lower latency than a cold prefill. A correct answer at 0% hit would indicate recomputation, not persistence.

= Research questions and hypotheses
- *RQ1.* Why does disk-backed restore report a high hit rate yet return an incorrect buried key?
- *RQ2.* Can all full-attention kernel pages be persisted and restored without enlarging the GPU staging allocation beyond device capacity?
- *RQ3.* Does the corrected path preserve byte-exact output across lengths, restarts, repetitions, and independent namespaces?
- *RQ4.* Does persistent restore materially reduce prefill latency relative to a never-stored cold control?

*H1* predicts that the failure is caused by layout geometry, not tensor-parallel rank mismatch. *H2* predicts exact recovery only when every kernel page is transferred with immutable per-page metadata. *H3* predicts increasing relative benefit with context length. Any wrong key, non-finite output, unexpected 0% hit, cross-namespace hit, engine death, or timeout rejects the run.

= System under test
#table(
  columns: (37mm, 1fr), inset: 6pt, stroke: .4pt + rgb("c7cdd5"),
  [*Model*], [Qwen3.8-27B W4A16 AWQ; hybrid GDN/full attention],
  [*Runtime*], [vLLM 0.27.1; tensor parallelism 2],
  [*Accelerators*], [2 × NVIDIA RTX PRO 2000 Blackwell, 16 GiB each],
  [*Persistent cache*], [LMCache 0.5.3 multiprocess; CPU L1 and disk-backed L2],
  [*Speculative decode*], [MTP-3 enabled],
  [*Hybrid mode*], [Mamba align],
  [*Unified chunk*], [1,600 tokens],
  [*Full-attention page*], [64 tokens; 25 kernel pages per chunk],
  [*Scheduler budget*], [`max_num_batched_tokens = 3199`],
)

= Root-cause analysis
== Geometry misclassification
vLLM ≥ 0.26 represents the relevant full-attention cache as a four-dimensional packed layout. LMCache 0.5.3's `_SubpagedAttentionViewEdit` path did not match this layout and treated a 1,600-token full-attention chunk as if it were one 64-token page. The ratio is:

$ R = 1600 / 64 = 25 " kernel pages per logical chunk". $

Consequently, each persisted full-attention object contained only 1/25 of the required payload. The recurrent GDN objects still matched, so aggregate hit rate remained near 99% and masked the semantic failure.

#figure(
  box(width: 100%, inset: 12pt, fill: rgb("f4f8f9"), stroke: .7pt + accent, radius: 3pt)[
    #grid(columns: (1fr, 10mm, 1fr), align: center,
      align(center)[*Faulty interpretation*\1 logical chunk\↓\1 × 64-token page\~1.1 MiB],
      text(size: 18pt, fill: accent)[→],
      align(center)[*Correct interpretation*\1 logical chunk\↓\25 × 64-token pages\~26.6 MiB],
    )
  ],
  caption: [Figure 1. The geometry error persisted one full-attention kernel page where 25 were required for each 1,600-token chunk.],
)

== Asynchronous metadata corruption
A first pagewise implementation packed the correct object size but mutated a shared `meta.address` while asynchronous transfers were still using it. The allocator keyed pinned host buffers by that mutable address, causing pages to land at incorrect offsets. Stored objects were approximately 96% zero even though restore faithfully read them back.

The working solution introduced an independent `_FaPageProxy` for each page. Each proxy owns copied metadata and exposes a page-specific data pointer while the base object's metadata remains immutable. The same native transfer mechanism is used pagewise in both directions. This eliminated host corruption without allocating a 25× GPU staging buffer.

== Diagnostic failure that obscured the bugs
A local diagnostic handler shadowed a timestamp variable with a status dictionary, causing a `TypeError` after transfer. The unresolved future appeared as a worker-timeout hang. This defect was in the diagnostic layer, not LMCache upstream, but delayed isolation of the transfer defects. It was removed before final verification.

= Implementation
The published patch modifies four LMCache files. Its functional responsibilities are:
1. identify the hybrid full-attention group from layout geometry rather than the obsolete view assumption;
2. map each logical chunk to all 25 kernel pages;
3. transfer those pages individually using independent proxy metadata;
4. restore the full used size for persistence and prefetch accounting;
5. preserve existing GDN object-group behavior and tensor-parallel worker isolation.

Patch revision 2 has SHA-256 `ec14d5012bef7a86e1ed90c6ada8ee1cbf27a7fe7b921a5ff8f83364efaa7de9`. It was applied to a pristine `lmcache==0.5.3` installation with a clean dry run and no fuzz. All patched files were byte-compared after application.

= Experimental methodology
A random `K-<24 hex>` value was inserted into each test document. The store phase used an uncached namespace and required 0% external hit. Both vLLM and the LMCache server were then fully stopped and restarted. The restore phase used disk-backed L2 as the surviving tier and asked for the buried key. Correctness was checked programmatically against both the expected key and content SHA-256.

The hard suite included three lengths, an immediate warm re-ask, a never-stored cold control, and two independent repeatability cycles. Six vLLM restarts and six LMCache-server restarts occurred during the campaign. Timing metrics were end-to-end wall time and time to first token (TTFT). TTFT is the more direct measure of avoided prefill work.

= Results
== Multi-length store and restore
#table(
  columns: (16mm, 22mm, 22mm, 18mm, 22mm, 22mm, 18mm, 18mm),
  inset: 4pt, stroke: .4pt + rgb("c7cdd5"),
  [*Context*], [*Restore wall*], [*Cold wall*], [*Wall ×*], [*Restore TTFT*], [*Cold TTFT*], [*TTFT ×*], [*Hit*],
  [5k], [2.13 s], [5.62 s], [2.6×], [1.00 s], [4.95 s], [5.0×], [97.0%],
  [13k], [2.31 s], [13.08 s], [5.7×], [1.58 s], [12.62 s], [8.0×], [98.8%],
  [26k], [3.60 s], [27.41 s], [7.6×], [2.72 s], [26.97 s], [9.9×], [98.7%],
)

Every restore returned the exact buried key. Relative benefit increased with context length because more prefill computation was avoided.

== Complete hard-suite outcome
#table(
  columns: (15mm, 1fr, 18mm, 19mm, 1fr), inset: 5pt, stroke: .4pt + rgb("c7cdd5"),
  [*Runs*], [*Scenario*], [*Hit*], [*Result*], [*Purpose*],
  [3], [5k/13k/26k store], [0.0%], [3/3], [Establish disk objects and cold baselines],
  [3], [Restore after full restart], [97.0–98.8%], [3/3], [Persistence and exactness],
  [1], [13k warm re-ask], [98.8%], [1/1], [Idempotence],
  [1], [Never-stored cold control], [0.0%], [1/1], [No cross-namespace leakage],
  [4], [Two independent 13k cycles], [0% store; 98.8% restore], [4/4], [Repeatability],
  [*12*], [*Total*], [], [*12/12*], [],
)

The cold control returned the correct key with 0% external hit and full prefill latency, proving that semantic correctness alone does not imply cache reuse. Restore/store answers and content hashes were byte-identical within every namespace.

= Discussion
The rank-mismatch hypothesis was falsified: both tensor-parallel ranks exhibited the same empty logical destination and later produced distinct, valid page hashes when geometry was corrected. The decisive variable was the 25:1 chunk-to-page geometry. Full GPU expansion failed because it reduced available KV capacity below the 131k requirement and exhausted pinned memory; CPU-only packing was correct but stalled service. Pagewise native transfer with immutable proxy metadata provided the required correctness and operational performance.

The near-99% hit rate observed before the fix demonstrates why cache lookup metrics cannot serve as correctness evidence for hybrid models. Most object groups can match while a smaller but semantically essential full-attention group is incomplete. End-to-end content validation must therefore be part of persistent-cache acceptance.

= Negative results and avoided paths
The investigation tested and rejected destination guessing, reversed destinations, selective GDN skipping, one-page expansion, full-size GPU staging, CPU `index_copy_`, and mutable shared metadata. These failures are retained in the engineering log to prevent repetition. A high hit rate with a wrong or truncated key was always classified as failure; an exact key at 0% hit was classified as recomputation rather than restore success.

= Threats to validity and non-claims
- The principal hard suite used one Qwen3.8 model, vLLM 0.27.1, LMCache 0.5.3, and one dual-GPU hardware class.
- A smaller TP=1 hybrid reproduced the geometry behavior, but this is not exhaustive portability evidence.
- Exact-prefix restore does not imply token reordering, arbitrary prefix editing, CacheBlend-style recombination, or cross-model transfer.
- Timing differences between patch revisions affected both cold and restore arms and are attributed to run variation plus removed diagnostics, not a changed restore algorithm.
- The paper does not claim universal applicability to future LMCache or vLLM layouts.

= Security, privacy, and disclosure
Namespaces and keys were synthetic. No customer data, secrets, credentials, private endpoints, or internal addressing are published. Cache namespaces must be salted per tenant or project in production designs. The public patch retains its upstream license obligations, and third-party ownership is preserved.

= Reproducibility and artifacts
The public fix repository contains the patch, explainer, and verification steps [2]. The private Stillpoint evidence record retains all hard-suite JSON outputs, summaries, and logs. Artifacts copied from the test host were SHA-256 verified at both source and destination. The canonical report identifies the exact patch digest and pristine-package procedure.

= Conclusion
LMCache 0.5.3 multiprocess restore for the tested hybrid model failed because full-attention chunk geometry was misclassified and asynchronous page transfers reused mutable metadata. Geometry-aware page expansion with independent page proxies restored every required page without 25× GPU staging. The corrected implementation passed 12/12 hard-suite runs, reproduced every buried key exactly after full service restart, achieved 97.0–98.8% external hit, and reduced TTFT by 5.0×–9.9× versus matched cold prefills. PIN-0001 is green for the declared configuration.

= References
1. LMCache Project, “LMCache,” release 0.5.3, persistent KV-cache software. #link("https://github.com/LMCache/LMCache"). Accessed 4 September 2026.
2. 4rce.com Digital Technologies GmbH, “LMCache Hybrid GDN Restore Fix,” patch and technical explainer, revision 2, 2026. #link("https://github.com/dl4rce/lmcache-hybrid-gdn-restore-fix").
3. vLLM Project, “vLLM: Easy, Fast, and Cheap LLM Serving with PagedAttention,” software version 0.27.1. #link("https://github.com/vllm-project/vllm"). Accessed 4 September 2026.
4. Qwen Team, “Qwen,” model and technical resources. #link("https://github.com/QwenLM/Qwen3"). Accessed 4 September 2026.
5. NVIDIA, “Gated Delta Networks: Improving Mamba2 with Delta Rule,” arXiv:2412.06464, 2024. #link("https://arxiv.org/abs/2412.06464").
6. LMCache Project, “Hybrid model restore layout issue,” issue 4701, 2026. #link("https://github.com/LMCache/LMCache/issues/4701").

= Revision history
- *2026-08-22, revision 2:* pristine-install re-verification completed; 12/12 hard suite passed.
- *2026-09-04, version 2.0:* independent scientific typesetting, consolidated methods, root-cause analysis, negative results, and limitations.
