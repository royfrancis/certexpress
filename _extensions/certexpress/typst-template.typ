#set text(fill: rgb("#444444"))
#set par(leading: 0.7em)
#set block(spacing: 1.4em)

#let certexpress(

  title: none,
  date: none,
  headnotes-1: none,
  headnotes-2: none,
  gap: 72pt,
  participant: none,
  bg-image: none,
  logo-image: none,
  sign-image: none,
  sign-height: 15mm,
  teacher: none,
  footnotes: none,
  version: "Unknown",
  font-heading: "Impact",
  font-body: "Comic Neue",
  body

) = {

  // body font.
  set text(12.5pt, font: font-body)

  set page(
    margin: (left: 2.5cm, right: 2.5cm, top: 4.5cm, bottom: 5cm),
    background: if bg-image != none {
      place(center + top, image(bg-image.path, height: 100%))
    },
    header: grid(
      columns: (1fr, 1fr),
      row-gutter: 0pt,
      grid(
        columns: 1fr,
        rows: (12pt, 14pt),
        row-gutter: 5pt,
        text(font: font-heading, fill: silver, weight: "medium", size: 11pt, tracking: 1.05pt, align(left + bottom, headnotes-1)),
        text(font: font-heading, fill: silver, weight: "medium", size: 14pt, tracking: 1.1pt, align(left + bottom, headnotes-2))
      ),
      pad(y: -14pt, align(right, image(logo-image.path, height: 18mm)))
    ),
    footer: {
      set text(8pt)
      set par(leading: 0.5em)
      set block(spacing: 1em)
      set par(justify: true)
      footnotes
      set text(6pt)
      pad(top: 1pt, version + h(1pt) + date)
    }
  )

  // configure headings.
  // show heading: set text(font: "Impact")
  show heading.where(level: 1): set text(size: 1.1em)
  show heading.where(level: 1): set par(leading: 0.4em)
  show heading.where(level: 1): set block(below: 0.8em)
  show heading: it => {
    set text(weight: 600) if it.level > 2
    it
  }

  // underline links.
  show link: underline

  // page body
  grid(
    columns: 1fr,
    row-gutter: 20pt,

    // title.
    pad(
      top: 10pt,
      bottom: gap,
      text(font: font-heading, size: 36pt, fill: silver, weight: 700, tracking: 1.3pt, title)
    ),

    // participant name
    text(22pt, weight: 600, participant),

    // body flow
    {
      set par(justify: true)
      body
      if sign-image != none {
        image(sign-image.path, height: sign-height)
      }
      teacher
    }
  )
}
