// History:
//  Jan 10 13 tcolar Creation
//

using concurrent
using webmod
using web
using markdown
using mustache
using netColarUtils

**
** PageWeblet : Serves pages
**
class PageWeblet : Weblet
{
  ** Send a page
  Void page(Str:Str args)
  {
    page := args["page"]
    ns := args["namespace"]

    // Draft routing is a little strange where /blah/ would give no namespace page="blah"
    // So fix it as we need it to be.
    if(req.uri.pathOnly.toStr.endsWith("/"))
    {
      ns = page
      page = "home"
    }

    if(page ==null || page.trim.isEmpty) page = "home"
    if(ns == null || ns.trim.isEmpty) ns = "default"

    nsSettings := NsSettings.loadFor(ns)
    pageOpts := PageSettings.loadFor(ns, page)

    // check for rootFile requests and short-circuit if matches
    if(nsSettings.rootFiles.contains(page))
    {
      path := GlobalSettings.root.uri + `$ns/files/$page`
      Fantomato.serveFile(path, res)
      return
    }

    req.session["fantomato.ns"] = ns
    req.session["fantomato.tpl"] = nsSettings.template
    req.session["fantomato.page"] = page

    content := read(ns, page)

    // process a page
    if(content == null)
    {
      res.headers["Content-Type"] = "text/html"
      res.statusCode = 404
      notFound := read(ns, "404") ?: "<b>Error 404 -> Page not found : $page</b>"
      res.out.print(templatize(ns, notFound, "404", nsSettings, pageOpts)).close
      return
    }

    // ok send the page
    Fantomato.log.info("Sending $ns :: $page")
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200

    wholePage := templatize(ns, content, page, nsSettings, pageOpts)
    res.out.print(wholePage).close
  }

  ** Create the whole page by inserting the content into the template
  ** Also insert variable values in the template as well
  internal Str templatize(Str ns, Str content, Str pageName,
                          NsSettings nsSettings, PageSettings pageOpts)
  {
    tplName := nsSettings.template
    tplPage := pageOpts.page
    file := GlobalSettings.root + `tpl/$tplName/$tplPage`
    Str? tpl := (Str?) Cache.readCachedFile(file)?.content
    if(tpl == null)
    {
      Fantomato.log.info("No template for $ns ! Will use the default one.")
      tpl = (Str?) Cache.readCachedFile(GlobalSettings.root + `tpl/default/$tplPage`)?.content
      tpl = tpl ?: "<html><body>MISSING TEMPLATE : 'page' for namespace $ns !</body><html>"
    }

    // pocess the template with mustache
    args := [ "title"          : pageName.replace("_"," "),
              "generatedDate"  : DateTime(Pod.of(this).meta["build.ts"]).toHttpStr,
              "content"        : content,
              "import"         : importLambda,
              "ap"             : activePathLambda,
              "showtags"       : tagsLambda,
              "googleAnalytics": nsSettings.getGaCode,
               // in case somebody rather use custom GA js code
              "gaId"           : nsSettings.googleAnalyticsId,
              "author"         : pageOpts.author,
              "addThisId"      : nsSettings.addThisId,
            ]

    if( ! nsSettings.addThisId.isEmpty)
      args["addThisEnabled"] = true

    // comments
    if(pageName != "404" && pageOpts.commentsEnabled)
    {
      args["commentsEnabled"] = true
    }

    // user defined vars
    nsSettings.variables.each |v, k| {args[k] = v}
    pageOpts.variables.each |v, k| {args[k] = v}

    tpl = Mustache(tpl.in).render(args)
        + "\n\n<!--Powered By FantoMato http://www.status302.com/fantomato/-->\n"

    return tpl
  }

  ** lambda to show the lits of all known tags as a list (<li> tags)
  ** Tags that are active on the current page get bolded
  Func tagsLambda := |Str var, |Str->Obj?| context, Func render -> Obj?|
  {
    ns := getNs
    page := req.uri.path.last ?: "home"
    allTags := Fantomato.tagger.send("tags").get as Str:Int
    html := ""
    tags := PageSettings.loadFor(ns, page).tags
    allTags.keys.sort.each |tag|
    {
      prefix := ns == "default" ? "" : "/$ns"
      html += "<li><a href='_tag/$tag'>"
            + (tags.contains(tag) ? "<b>" : "")
            + "$tag (${allTags[tag]})"
            + (tags.contains(tag) ? "</b>" : "")
            + "</a></li>"
    }
    return html
  }

  ** lambda to import page bits in a template
  Func importLambda := |Str var, |Str->Obj?| context, Func render -> Obj?|
  {
    ns := getNs
    return read(ns, var.trim) ?: ""
  }

  ** lambda to set class="active" if we are on the given page
  Func activePathLambda := |Str var, |Str->Obj?| context, Func render -> Obj?|
  {
    page := req.uri.path.last ?: "home"
    return page.trim == var.trim ? "class='active'" : ""
  }

  internal Str getNs()
  {
    if(req.uri.path.size > 1)
      return req.uri.path[0]
    path := req.uri.pathOnly.toStr
    return req.uri.path.isEmpty || ! path.endsWith("/") ? "default" : req.uri.path[0]
  }

  ** Read the page (lazy cached)
  ** Returns null if missing / failed
  internal Str? read(Str ns, Str pageName)
  {
    Str base := "$ns/pages/${pageName}"

    // Look for page.html or page.md
    file := GlobalSettings.root + `${base}.html`
    if( ! file.exists)
      file = GlobalSettings.root + `${base}.md`
    if( ! file.exists)
      file = GlobalSettings.root + `${base}.txt`

    if(! file.exists)
      return null

    cached := Cache.readCachedFile(file, "parse")
    return cached.content as Str
  }

  ** Shows all knwon links for a tag
  Void tag(Str:Str args)
  {
    ns := args["ns"] ?: "default"
    nsSettings := NsSettings.loadFor(ns)
    req.session["fantomato.ns"] = ns
    req.session["fantomato.tpl"] = nsSettings.template
    req.session["fantomato.page"] = "_tags"
    tag := args["tag"]
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200

    TaggedPage[] pages := Fantomato.tagger.send(["tag", tag]).get
    content := "<h3>Pages with the '$tag' tag:</h3><ul>"
    pages.each
    {
      content += "<li><a href='$it.link'>$it.page</a></li>"
    }
    content+="</ul>"
    wholePage := templatize(ns, content, "tag", nsSettings, PageSettings{commentsEnabled = false})
    res.out.print(wholePage).close
  }
}