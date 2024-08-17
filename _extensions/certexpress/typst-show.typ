#show: certexpress.with(
  $if(title)$
    title: "$title$",
  $endif$

  $if(headnotes-1)$
    headnotes-1: [$headnotes-1$],
  $endif$

  $if(headnotes-2)$
    headnotes-2: [$headnotes-2$],
  $endif$

  $if(participant)$
    participant: [$participant$],
  $endif$

  $if(bg-image)$
    bg-image: (
      path: "$bg-image.path$"
    ), 
  $endif$

  $if(logo-image)$
    logo-image: (
      path: "$logo-image.path$"
    ), 
  $endif$

  $if(sign-image)$
    sign-image: (
      path: "$sign-image.path$"
    ), 
  $endif$

  $if(sign-height)$
    sign-height: $sign-height$,
  $endif$

  // $if(gap)$
  //   gap: $gap$,
  // $endif$

  $if(teacher)$
    teacher: [$teacher$],
  $endif$

 $if(footnotes)$
    footnotes: [$footnotes$],
  $endif$

  $if(version)$
    version: [$version$],
  $endif$

  $if(date)$
    date: [$date$],
  $endif$
)
