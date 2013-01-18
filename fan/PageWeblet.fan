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

    req.session["fantomato.ns"] = ns
    req.session["fantomato.tpl"] = nsSettings.template

    content := read(ns, page)

    if(content == null)
    {
      if(page.lower != "favicon.ico"  && page.lower != "robots.txt")
        Fantomato.log.info("Not found : $ns:$page")
      res.headers["Content-Type"] = "text/html"
      res.statusCode = 404
      notFound := read(ns, "404") ?: "<b>Error 404 -> Page not found : $page</b>"
      res.out.print(templatize(ns, notFound, page, nsSettings, pageOpts)).close
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
              "googleAnalytics": nsSettings.getGaCode,
               // in case somebody rather use custom GA js code
              "gaId"           : nsSettings.googleAnalyticsId,
              "author"         : pageOpts.author,
              "addThisId"      : nsSettings.addThisId,
            ]

    if( ! nsSettings.addThisId.isEmpty)
      args["addThisEnabled"] = true

    // user defined vars
    nsSettings.variables.each |v, k| {args[k] = v}
    pageOpts.variables.each |v, k| {args[k] = v}

    // comments
    // TODO: maybe provide options to control comments caching as it could get rather large
    nbComments := nsSettings.commentsPerPage
    if(nbComments > 0 && pageOpts.commentsEnabled)
    {
      args["commentsEnabled"] = true
      fc := GlobalSettings.root + `$ns/comments//${pageName}.json`
      if(fc.exists)
      {
        comments := (PageComment[]?) Cache.readCachedFile(fc, "comments")?.content
        if(comments != null)
        {
          max := comments.size
          if(!req.uri.query.containsKey("allComments") && max > nbComments)
            max = nbComments
          args["comments"] = comments[0 ..< max]
          if(comments.size - max > 0)
          {
            args["moreComments"] = true
            args["commentsLeft"] = comments.size - max
          }
        }
      }
    }

    tpl = Mustache(tpl.in).render(args)
        + "\n\n<!--Powered By FantoMato http://www.status302.com/fantomato/-->\n"

    return tpl
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
}