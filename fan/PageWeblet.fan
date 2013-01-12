// History:
//  Jan 10 13 tcolar Creation
//

using concurrent
using webmod
using web
using markdown
using mustache

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

    content := read(ns, page)

    if(content == null)
    {
      Fantomato.log.info("Not found : $ns:$page")
      res.headers["Content-Type"] = "text/html"
      res.statusCode = 404
      notFound := read(ns, "404") ?: "<b>Error 404 -> Page not found : $page</b>"
      res.out.print(templatize(ns, notFound, page)).close
      return
    }

    // ok send the page
    Fantomato.log.info("Serving $page .")
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200

    wholePage := templatize(ns, content, page)
    res.out.print(wholePage).close
  }

  ** Create the whole page by inserting the content into the template
  ** Also insert variable values in the template as well
  internal Str templatize(Str ns, Str content, Str pageName)
  {
    tpl := read(ns, "page", true)
      ?: "<html><body>MISSING TEMPLATE : 'page' for namespace $ns !</body><html>"

    // pocess the template with mustache
    args := [ "title"          : pageName.replace("_"," "),
              "generatedDate"  : DateTime(Pod.of(this).meta["build.ts"]).toHttpStr,
              "content"        : content,
              "import"         : importLambda,
              "ap"             : activePathLambda,
            ]

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
    return req.uri.pathOnly.toStr.endsWith("/") ? req.uri.path[0] : "default"
  }

  ** Read the page (lazy cached)
  ** Returns null if missing / failed
  internal Str? read(Str ns, Str pageName, Bool isTpl := false)
  {
    p := "${ns}:${pageName}"
    cached := cacheGet(p)

    Str base := isTpl ? "tpl/$ns/" : "$ns/pages/"

    // Look for page.html or page.md
    file := Fantomato.settings.root + `$base${pageName}.html`
    if( ! file.exists)
      file = Fantomato.settings.root + `$base${pageName}.md`
    if( ! file.exists)
      file = Fantomato.settings.root + `$base${pageName}.txt`

    if(! file.exists)
      return null

    if(cached == null || file.modified > cached.ts)
    {
      content := file.readAllStr

      if(file.ext == "md")
      {
        // convert Markdown to Html
        content = Markdown().markdown(content)
      }
      else if(file.ext == "txt")
      {
        // jotwiki format
        content = WikiProcessor().process(content)
      }

      Fantomato.log.info("Adding to cache : $p")
      cached = CachedPage(content, file.modified)
      cacheSet(p, cached)
    }

    return cached.text
  }

  internal CachedPage? cacheGet(Str key)
  {
    if(! Actor.locals.containsKey("fantomato.cache"))
      Actor.locals["fantomato.cache"] = Str:CachedPage[:]
    map := Actor.locals["fantomato.cache"] as Str:CachedPage
    return map[key]
  }

  internal Void cacheSet(Str key, CachedPage page)
  {
    if(! Actor.locals.containsKey("fantomato.cache"))
      Actor.locals["fantomato.cache"] = Str:CachedPage[:]
    map := Actor.locals["fantomato.cache"] as Str:CachedPage
    map[key] = page
  }

  ** Replace vars in the template
  ** vars are varName: value
  ** in the page they are as {{varName}}
  internal Str replaceVars(Str page, Str:Str vars)
  {
    vars.each |val, varName| {page = page.replace("{~$varName~}", val)}
    return page
  }
}