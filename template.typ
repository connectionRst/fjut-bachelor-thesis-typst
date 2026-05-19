#import "./chinese_utils.typ": *

#let lengthceil(len, unit: 字号.小四) = calc.ceil(len / unit) * unit
#let partcounter = counter("part")
#let chaptercounter = counter("chapter")
#let appendixcounter = counter("appendix")
#let footnotecounter = counter(footnote)
#let rawcounter = counter(figure.where(kind: "code"))
#let imagecounter = counter(figure.where(kind: image))
#let tablecounter = counter(figure.where(kind: table))
#let equationcounter = counter(math.equation)
// TODO: remove this
#let appendix() = {
  appendixcounter.update(10)
  chaptercounter.update(0)
  counter(heading).update(0)
}
#let skippedstate = state("skipped", false)
#let artstartedstate = state("article_started", false)

#let chinesenumbering(..nums, location: none, brackets: false) = context {
  let actual_loc = if location == none { here() } else { location }
  if appendixcounter.at(actual_loc).first() < 10 {
    if nums.pos().len() == 1 {
      "第" + str(nums.pos().first()) + "章"
    } else {
      numbering(if brackets { "(1.1)" } else { "1.1" }, ..nums)
    }
  } else {
    if nums.pos().len() == 1 {
      "附录 " + numbering("A.1", ..nums)
    } else {
      numbering(if brackets { "(A.1)" } else { "A.1" }, ..nums)
    }
  }
}

#let chineseoutline(title: "目录", depth: none, indent: false) = {
  heading(title, numbering: none, outlined: false)
  context {
    // first in first, reset pagenum
    counter(page).update(1)
    set text(font: 字体.宋体, size: 字号.小四)
    let line(el, indent, maybe_number) = {
      if indent {
        h(1em * (el.level - 1 ))
      }

      if maybe_number != none {
        context {
          let width = measure(maybe_number).width
          box(
            width: lengthceil(width),
            link(el.location(), if el.level == 1 {
              strong(maybe_number)
            } else {
              maybe_number
            })
          )
        }
      }

      link(el.location(), 
        if el.has("body") { el.body } else {el}
      )

      // Filler dots
      box(width: 1fr, h(10pt) + box(width: 1fr, repeat[.]) + h(10pt))

      // Page number
      let footer = query(selector(<__footer__>).after(el.location()))
      footer.first()

      linebreak()
      v(-0.2em)
    }
    let it = here()
    let abstracts = query(<abstracts>)
    
    let elements = query(heading.where(outlined: true))
    for el in abstracts {
      line(el, false, none)
    }
    for el in elements {
      // Skip headings that are too deep
      if depth != none and el.level > depth { continue }

      let maybe_number = if el.numbering != none {
        if el.numbering == chinesenumbering {
          chinesenumbering(..counter(heading).at(el.location()), location: el.location())
        } else {
          numbering(el.numbering, ..counter(heading).at(el.location()))
        }
        h(0.5em)
      }

      line(el, indent, maybe_number)
    }
  }
}

#let listoffigures(title: "插图", kind: image) = {
  heading(title, numbering: none, outlined: false)
  context {
    let it = here()
    let elements = query(figure.where(kind: kind).after(it))

    for el in elements {
      let maybe_number = {
        let el_loc = el.location()
        chinesenumbering(chaptercounter.at(el_loc).first(), counter(figure.where(kind: kind)).at(el_loc).first(), location: el_loc)
        h(0.5em)
      }
      let line = {
        context {
          let width = measure(maybe_number).width
          box(
            width: lengthceil(width),
            link(el.location(), maybe_number)
          )
        }

        link(el.location(), el.caption.body)

        // Filler dots
        box(width: 1fr, h(10pt) + box(width: 1fr, repeat[.]) + h(10pt))

        // Page number
        let footers = query(selector(<__footer__>).after(el.location()))
        let page_number = if footers == () {
          0
        } else {
          counter(page).at(footers.first().location()).first()
        }
        link(el.location(), str(page_number))
        linebreak()
        v(-0.2em)
      }

      line
    }
  }
}

#let codeblock(raw, caption: none, outline: false) = {
  figure(
    if outline {
      rect(width: 100%)[
        #set align(left)
        #raw
      ]
    } else {
      set align(left)
      raw
    },
    caption: caption, kind: "code", supplement: ""
  )
}

#let booktab(columns: (), aligns: (), width: auto, caption: none, ..cells) = {
  let headers = cells.pos().slice(0, columns.len())
  let contents = cells.pos().slice(columns.len(), cells.pos().len())
  set align(center)

  if aligns == () {
    for i in range(0, columns.len()) {
      aligns.push(center)
    }
  }

  let content_aligns = ()
  for i in range(0, contents.len()) {
    content_aligns.push(aligns.at(calc.rem(i, aligns.len())))
  }

  return figure(
    block(
      width: width,
      grid(
        columns: (auto),
        row-gutter: 1em,
        line(length: 100%),
        [
          #set align(center)
          #box(
            width: 100% - 1em,
            grid(
              columns: columns,
              ..headers.zip(aligns).map(it => [
                #set align(it.last())
                #strong(it.first())
              ])
            )
          )
        ],
        line(length: 100%),
        [
          #set align(center)
          #box(
            width: 100% - 1em,
            grid(
              columns: columns,
              row-gutter: 1em,
              ..contents.zip(content_aligns).map(it => [
                #set align(it.last())
                #it.first()
              ])
            )
          )
        ],
        line(length: 100%),
      ),
    ),
    caption: caption,
    kind: table
  )
}

#let conf(
  cauthor: "张三",
  eauthor: "San Zhang",
  studentid: "23000xxxxx",
  blindid: "L2023XXXXX",
  cthesisname: "毕业设计（论文）",
  cheader: "北京大学博士学位论文",
  ctitle: "北京大学学位论文 Typst 模板",
  etitle: "Typst Template for Peking University Dissertations",
  school: "某个学院",
  cfirstmajor: "某个一级学科",
  cmajor: "某个专业",
  emajor: "Some Major",
  clazz: "某个班级",
  csupervisor: "李四",
  esupervisor: "Si Li",
  date: "二零二三年六月",
  cnki: "cnki.pdf",
  cabstract: [],
  ckeywords: (),
  eabstract: [],
  ekeywords: (),
  acknowledgements: [],
  linespacing: 20pt,
  outlinedepth: 3,
  blind: false,
  listofimage: true,
  listoftable: true,
  listofcode: true,
  alwaysstartodd: true,
  doc,
) = {
  let smartpagebreak = () => {
    if alwaysstartodd {
      pagebreak(weak: true)  // workaround for current page no pagenum
      skippedstate.update(true)
      pagebreak(to: "odd", weak: true)
      skippedstate.update(false)
    } else {
      pagebreak(weak: true)
    }
  }

  set page("a4",
    header: context {
      set text(字号.五号, font: 字体.宋体)
      set align(center)
      let firstpart = query(heading.where(outlined: true, level: 1)).first().location().page()
      // if here().page() >= firstpart {
      if partcounter.get().first() == 20 {  // <10 is cover--contents, 10~20 is the article, 30 is appendix (unused)
        // even 才是偶数
        let partpage = here().page() - firstpart + 1
        if calc.even(partpage) or partpage == 1 {
          [
            #align(center, cheader)
            #v(-0.8em)
            #line(length: 100%)
          ]
        } else {
          let footers = query(selector(<__footer__>).after(here()))
          if footers != () {
            [
              #cauthor
              #h(0.5em)
              #ctitle
              #v(-0.8em)
              #line(length: 100%)
            ]
          }
        }
      }
    },
    footer: context {
      if skippedstate.get() and calc.even(here().page()) { return }
      [  // TODO: migrate this part to script mode
        #set text(字号.五号, font: 字体.宋体, weight: "regular")
        #set align(center)
        #{
          let part = partcounter.get().first()
          if part < 20 {
            numbering("I", counter(page).at(here()).first())
          } else {
            str(counter(page).at(here()).first())
          }
        }
        #label("__footer__")
      ]
    },
  )

  set text(字号.一号, font: 字体.宋体, lang: "zh")
  set align(center + horizon)
  set heading(numbering: chinesenumbering)
  set figure(
    numbering: (..nums) => context {
      if appendixcounter.at(here()).first() < 10 {
        numbering("1.1", chaptercounter.at(here()).first(), ..nums)
      } else {
        numbering("A.1", chaptercounter.at(here()).first(), ..nums)
      }
    }
  )
  set math.equation(
    numbering: (..nums) => context {
      set text(font: 字体.宋体)
      if appendixcounter.at(here()).first() < 10 {
        numbering("(1.1)", chaptercounter.at(here()).first(), ..nums)
      } else {
        numbering("(A.1)", chaptercounter.at(here()).first(), ..nums)
      }
    }
  )
  set list(indent: 2em)
  set enum(indent: 2em)

  show strong: it => text(font: 字体.黑体, weight: "semibold", it.body)
  show emph: it => text(font: 字体.楷体, style: "italic", it.body)
  show raw: set text(font: 字体.代码)

  show heading: it => {
    // Cancel indentation for headings
    set par(first-line-indent: 0em)
    if it.level == 1 {
      if it.outlined {  // other magic part manually handle them in text flow
        // smartpagebreak()  // no requirement to use odd-even page in parts. At least in offcial document & template.
        if (partcounter.get().first() == 20) {
          pagebreak(weak: true)
        }
      }
      // manipulation by hard-encoded keywork has been removed
      // plz find them around the components & manually manaage partState `partcounter` & pagenum `counter(page)`.
      if it.numbering != none {
        chaptercounter.step()
      }
      footnotecounter.update(())
      imagecounter.update(())
      tablecounter.update(())
      rawcounter.update(())
      equationcounter.update(())
    }
    // calculate props
    let size-list = (字号.小二, 字号.三号, 字号.小三, 字号.小四)  // TODO: split this outside
    let index = if (it.level >= 1 and it.level <= 4) {it.level - 1} else {3}
    // set props
    set block(above: heading-above.at(index), below: heading-below.at(index))
    set text(size: size-list.at(index))
    set align(if (index == 0) {center} else {left})
    // display
    block[
      #if it.numbering != none {
        strong(counter(heading).display())
        h(0.5em)
      }
      #strong(it.body)
    ]
  }

  show figure: it => [
    #set align(center)
    #if not it.has("kind") {
      it
    } else if it.kind == image {
      it.body
      [
        #set text(字号.五号)
        #it.caption
      ]
    } else if it.kind == table {
      [
        #set text(字号.五号)
        #it.caption
      ]
      it.body
    } else if it.kind == "code" {
      [
        #set text(字号.五号)
        #context {[代码]+it.counter.display(it.numbering)+"   "}
        #it.caption.body 
      ]
      it.body
    }
  ]

  show ref: it => {
    if it.element == none {
      // Keep citations as is
      it
    } else {
      // Remove prefix spacing
      h(0em, weak: true)

      let el = it.element
      let el_loc = el.location()
      if el.func() == math.equation {
        // Handle equations
        link(el_loc, [
          式
          #chinesenumbering(chaptercounter.at(el_loc).first(), equationcounter.at(el_loc).first(), location: el_loc, brackets: true)
        ])
      } else if el.func() == figure {
        // Handle figures
        if el.kind == image {
          link(el_loc, [
            图
            #chinesenumbering(chaptercounter.at(el_loc).first(), imagecounter.at(el_loc).first(), location: el_loc)
          ])
        } else if el.kind == table {
          link(el_loc, [
            表
            #chinesenumbering(chaptercounter.at(el_loc).first(), tablecounter.at(el_loc).first(), location: el_loc)
          ])
        } else if el.kind == "code" {
          link(el_loc, [
            代码
            #chinesenumbering(chaptercounter.at(el_loc).first(), rawcounter.at(el_loc).first(), location: el_loc)
          ])
        }
      } else if el.func() == heading {
        // Handle headings
        if el.level == 1 {
          link(el_loc, chinesenumbering(..counter(heading).at(el_loc), location: el_loc))
        } else {
          link(el_loc, [
            节
            #chinesenumbering(..counter(heading).at(el_loc), location: el_loc)
          ])
        }
      }

      // Remove suffix spacing
      h(0em, weak: true)
    }
  }

  // Cover page

  {
    set page(footer: none)
    let fieldname(name) = [
      #set align(right + top)
      #text(name, font: 字体.仿宋)
    ]

    let fieldvalue(value) = [
      #set align(center + horizon)
      #set text(font: 字体.仿宋)
      #grid(
        rows: (auto, auto),
        row-gutter: 0.2em,
        value,
        line(length: 100%)
      )
    ]

   {
      image("logo.png")
      text(font: 字体.隶书, size: 字号.小初, cthesisname)

      set text(字号.二号)
      v(5em)
      set text(字号.三号)

      grid(
        // TODO: edit line width as module
        // columns: (80pt, 280pt),
        columns: (80pt, 300pt),
        row-gutter: 1em,
        fieldname(text("题") + h(2em) + text("目：")),
        fieldvalue(ctitle),
        fieldname(text("学") + h(2em) + text("生：")),
        fieldvalue(cauthor),
        fieldname(text("指导老师：")),
        fieldvalue(csupervisor),
        fieldname(text("学") + h(2em) + text("院：")),
        fieldvalue(school),
        fieldname(text("专") + h(2em) + text("业：")),
        fieldvalue(cmajor),
        fieldname([班#h(2em)级：]),
        fieldvalue(clazz),
        fieldname(text("学") + h(2em) + text("号：")),
        fieldvalue(studentid),
      )
      v(字号.五号)
      text(font:字体.隶书)[福建理工大学教务处 制]
      place(
        image("cover.png", height: 7.35cm, width: 22cm),
        dx: -3cm,
        dy: -1.41cm,
      )
    }

  }
  // 如果你不在计算机系，可能需要用下面这个参数，一切以实物为准真是笑yue了
  // set page(margin: (bottom: 2cm, right: 2cm))
  // TODO: as doc() arg
  set page(margin: (x: 3.17cm, y: 2.54cm))
  smartpagebreak()

  // TODO: move this part before cover
  set align(left + top)
  set text(font: 字体.宋体, 字号.小四)
  set par(justify: true, first-line-indent: (amount: 2em, all: true), leading: par-spacing(linespacing), spacing: par-spacing(linespacing))


  import "@preview/muchpdf:0.1.1": *
  let cnkipdf = read("cnki.pdf", encoding: none)
  if (cnkipdf.len() >= 0) {
    set page(footer: none, margin: 0pt)
    muchpdf(cnkipdf)
  } else {
    // cnki
    counter(page).update(1)
    {
      if not blind {
        set par(leading: par-spacing(25pt), spacing: par-spacing(25pt))
        set text(font: "DengXian", size: 字号.四号)
        set align(center)

        v(字号.三号*2.5)
        {
          set par(leading: 1.25em, spacing: 1.25em)
          [
            #strong[
              #align(center)[
                #text(size: 字号.三号)[
                  福建理工大学本科毕业设计（论文）作者承诺保证书
                ]
              ]
            ]
          ]
          {
            "本人郑重承诺：";
            "本篇毕业设计（论文）的内容真实、可靠。";
            "如果存在弄虚作假、抄袭的情况，本人愿承担全部责任。";
          } 
        }
        v(5em)
        {
          set par(first-line-indent: 17em)  // 👍
          set align(left)
          v(1em)
          par[学生签名：]
          v(1em)
          par[#h(2em)年 #h(1em) 月 #h(1em) 日]
          v(1em)
        }
        
        v(2em)
        
        [
          #strong[
            #align(center)[
              #text(size: 字号.三号)[
                福建理工大学本科毕业设计（论文）指导教师承诺保证书
              ]
            ]
          ]
        ]
        v(3em)
        align(left)[本人郑重承诺：我已按有关规定对本篇毕业设计(论文)的选题与内容进行了指导和审核，且提交的毕业设计（论文）终稿与上传至“大学生论文管理系统”检测的电子文档相吻合，未发现弄虚作假、抄袭的现象，本人愿承担指导教师的相关责任。]
        v(8em)  // FIXME: looks similar
        {
          set par(first-line-indent: 17em)
          set align(left)
          v(1em)
          par[指导教师签名：]
          v(1em)
          par[#h(2em)年 #h(1em) 月 #h(1em) 日]
        }
      }
    }
  }
  smartpagebreak()

  // FIXME: Abstract & 中文摘要 spacing
  // Chinese abstract
  counter(page).update(1)
  {
    {
      set align(center)
      set text(font: 字体.黑体)

      [
        #par(spacing: par-spacing(30pt))[
          #text(size: 字号.小二)[
            #ctitle
          ]
        ]
        #par(spacing: par-spacing(24pt))[
          #text(size: 字号.四号)[中文摘要]<abstracts>
        ]
      ]
    }
    cabstract
    {
      set par(first-line-indent: 0em, leading: par-spacing(16pt), spacing: par-spacing(16pt))
      text[*关键词：*]
      ckeywords.join("；")
    }

  }
  pagebreak(weak: true)

  // English abstract
  // not required to reset pagenum
  {
    set text(font: "Arial", weight: "black")
    {
      set align(center)
      set par(spacing: par-spacing(24pt), leading: par-spacing(24pt))
      par(text(etitle, size: 字号.小三))
      par[#text("Abstract", size: 字号.四号)<abstracts>]
    }
    set par(spacing: par-spacing(16pt), leading: par-spacing(16pt))
    set text(size: 字号.小四)
    text(eabstract, font: 字体.宋体, weight: "regular")

    set par(first-line-indent: 0em)
    [*KEYWORDS:*]
    h(0.5em, weak: true)
    ekeywords.join(", ")
  }

  // Table of contents
  // pagenum is reset in component
  // TODO: move out smartpagebreak() util
  smartpagebreak()
  chineseoutline(
    title: [目#h(2em)录],
    depth: outlinedepth,
    indent: true,
  )

  // TODO: unused, remove these
  {
    if listofimage {
      listoffigures()
    }

    if listoftable {
      listoffigures(title: "表格", kind: table)
    }

    if listofcode {
      listoffigures(title: "代码", kind: "code")
    }
  }

  // the article.
  smartpagebreak()
  counter(page).update(1)
  partcounter.update(20)
  set align(left + top)
  doc

  // acknow
  {
    if not blind {
      heading(numbering: none, "致谢")
      acknowledgements
    }
  }
}
