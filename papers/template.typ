#let stillpoint-paper(
  pin: none,
  title: none,
  subtitle: none,
  version: none,
  published: none,
  revised: none,
  status: none,
  abstract: none,
  keywords: (),
  canonical_url: none,
  pdf_url: none,
  body,
) = {
  set document(
    title: pin + " — " + title,
    author: ("Stillpoint Lab", "4rce.com Digital Technologies GmbH"),
    keywords: keywords,
  )
  set page(
    paper: "a4",
    margin: (top: 22mm, bottom: 22mm, left: 23mm, right: 23mm),
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 7.5pt, fill: rgb("596273"))
        grid(
          columns: (1fr, auto),
          gutter: 10pt,
          [#smallcaps[Stillpoint Lab] · #pin],
          [#title],
        )
        line(length: 100%, stroke: .45pt + rgb("c7cdd5"))
      }
    },
    footer: context {
      set text(size: 7pt, fill: rgb("687284"))
      line(length: 100%, stroke: .45pt + rgb("c7cdd5"))
      v(3pt)
      grid(
        columns: (1fr, auto, 1fr),
        [© 2026 4rce.com Digital Technologies GmbH],
        [#counter(page).display("1")],
        align(right)[#status · #version],
      )
    },
  )
  set text(font: ("New Computer Modern", "Libertinus Serif", "Times New Roman"), size: 9.5pt, fill: rgb("1f2937"), lang: "en")
  set par(justify: true, leading: .68em, spacing: .72em)
  set heading(numbering: "1.")
  show heading.where(level: 1): it => {
    v(10pt)
    text(size: 16pt, weight: "bold", fill: rgb("102a43"))[#it]
    v(3pt)
    line(length: 100%, stroke: 1pt + rgb("167d8d"))
    v(7pt)
  }
  show heading.where(level: 2): it => {
    v(8pt)
    text(size: 11.5pt, weight: "bold", fill: rgb("17465b"))[#it]
    v(3pt)
  }
  show link: it => text(fill: rgb("086f83"), it)
  show raw: it => text(font: ("Menlo", "DejaVu Sans Mono"), size: .88em, fill: rgb("17465b"), it)
  show table: set block(spacing: 8pt)
  show figure.caption: set text(size: 8pt, fill: rgb("4b5563"))

  // Independent title page for the archival paper.
  align(center)[
    #v(15mm)
    #text(size: 9pt, weight: "bold", tracking: 1.4pt, fill: rgb("167d8d"))[STILLPOINT LAB · TECHNICAL RESEARCH PAPER]
    #v(14mm)
    #text(size: 15pt, weight: "bold", fill: rgb("596273"))[#pin]
    #v(5mm)
    #text(size: 27pt, weight: "bold", fill: rgb("102a43"))[#title]
    #v(4mm)
    #text(size: 13pt, fill: rgb("4b6575"))[#subtitle]
    #v(18mm)
    #line(length: 42mm, stroke: 2pt + rgb("167d8d"))
    #v(12mm)
    #text(size: 11pt, weight: "bold")[Stillpoint Lab]
    #text(size: 10pt)[4rce.com Digital Technologies GmbH]
    #v(8mm)
    #grid(
      columns: (40mm, 70mm),
      row-gutter: 4pt,
      align: (right, left),
      text(size: 8.5pt, weight: "bold", fill: rgb("596273"))[Published], [#published],
      text(size: 8.5pt, weight: "bold", fill: rgb("596273"))[Revised], [#revised],
      text(size: 8.5pt, weight: "bold", fill: rgb("596273"))[Version], [#version],
      text(size: 8.5pt, weight: "bold", fill: rgb("596273"))[Status], [#status],
    )
    #v(1fr)
    #box(
      width: 100%,
      inset: 10pt,
      fill: rgb("eef5f6"),
      stroke: .7pt + rgb("9fc7cc"),
      radius: 3pt,
    )[
      #align(left)[
        #text(size: 8pt, weight: "bold", fill: rgb("17465b"))[CANONICAL PUBLICATION]
        #v(3pt)
        #text(size: 8pt)[HTML: #canonical_url]
        #linebreak()
        #text(size: 8pt)[PDF: #pdf_url]
      ]
    ]
    #v(8mm)
  ]

  pagebreak()
  heading(numbering: none, outlined: false)[Abstract]
  abstract
  v(7pt)
  text(size: 8.5pt, weight: "bold", fill: rgb("17465b"))[Keywords—]
  text(size: 8.5pt)[#keywords.join(", ")]
  v(12pt)
  box(width: 100%, inset: 10pt, fill: rgb("f4f6f8"), stroke: .5pt + rgb("c7cdd5"), radius: 2pt)[
    #text(size: 8pt, weight: "bold")[Document notice.]
    #text(size: 8pt)[ This PDF is an independently typeset archival research paper. The canonical mutable publication is #canonical_url. Quantitative claims are limited to the declared system, workloads, and repetitions.]
  ]
  v(10pt)
  outline(title: [Contents], depth: 2, indent: 14pt)
  pagebreak()
  body

  pagebreak(weak: true)
  heading(numbering: none, outlined: false)[Legal and publication notice]
  [© 2026 4rce.com Digital Technologies GmbH. All rights reserved. Stillpoint and Stillpoint Lab are research project names of 4rce.com. Original Stillpoint text, diagrams, benchmark analyses, and publication design are owned by 4rce.com Digital Technologies GmbH unless expressly stated otherwise. Third-party papers, software, code, product names, and trademarks remain the property of their respective owners. Citation and acknowledgement of upstream work do not transfer ownership.]
  v(6pt)
  [Imprint and privacy: #link("https://stillpointlab.dev/imprint.html")]
}
