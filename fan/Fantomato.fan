//
// History:
//   Aug 22, 2012 tcolar Creation
//

using draft
using web
using webmod
using concurrent
using markdown

**
** Master Server mod
** Route and serve the pages
**
const class Fantomato : DraftMod
{
  const Log log := Fantomato#.pod.log

  ** Constructor.
  new make()
  {
    // Rest of web services. Index pages, browsing etc ...
    pubDir = null
    logDir = `./log/`.toFile
    router = Router {
      routes = [
      // TODO: /FavIcon.ico
        Route("/index", "GET", #home),
        // Todo : /img/{*}
        // Todo : /{*}
      ]
    }
  }

  ** Send a page
  Void page(Str page)
  {
    content := read(page)

    if(content == null)
    {
      log.info("$page not found !")
      res.headers["Content-Type"] = "text/html"
      res.statusCode = 404
      res.out.print(top(page) + "404 - Page not found" + bottom).close
      return
    }

    // ok send the page
    log.info("Serving $page .")
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200

    res.out.print(top(page) + content + bottom).close
  }

  ** Just to map index to home
  Void home()
  {
    page("home")
  }

  Str top(Str pageName)
  {
    top := read("_top")
    vars := [ "title"          : pageName.replace("_"," "),
              "generatedDate"  : DateTime(Pod.of(this).meta["build.ts"]).toHttpStr,
              "bloglist" : read("_blog_list")]
    top = replaceVars(top, vars)
    return top
  }

  Str bottom()
  {
    read("_bottom")
  }

  ** Read the page (lazy cached)
  ** Returns null if missing / failed
  Str? read(Str page)
  {
    p := page.toStr
    content := cacheGet(p)
    if(content == null)
    {
      // Look for page.html or page.md

      file := Pod.of(this).file("/pages/${page}.html".toUri, false)
      if(file == null)
        file = Pod.of(this).file("/pages/${page}.md".toUri, false)

      if(file == null)
        return null

      content = file.readAllStr

      if(file.ext == "md")
      {
        // convert Markdown to Html
        content = Markdown().markdown(content)
      }

      log.info("Adding to cache : $page")
      cacheSet(p, content)
    }
    return content
  }

  Str? cacheGet(Str key)
  {
    if(! Actor.locals.containsKey("fantomato.cache"))
      Actor.locals["fantomato.cache"] = Str:Str[:]
    map := Actor.locals["fantomato.cache"] as Str:Str
    return map[key]
  }

  Void cacheSet(Str key, Str val)
  {
    if(! Actor.locals.containsKey("fantomato.cache"))
      Actor.locals["fantomato.cache"] = Str:Str[:]
    map := Actor.locals["fantomato.cache"] as Str:Str
    map[key] = val
  }

  ** Replace vars in the page
  ** vars are varName: value
  ** in the page they are as {{varName}}
  Str replaceVars(Str page, Str:Str vars)
  {
    vars.each |val, varName| {page = page.replace("{{$varName}}", val)}
    return page
  }
}

