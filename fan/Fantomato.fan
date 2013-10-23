// History:
//  Jan 09 12 tcolar Creation
//

using draft
using web
using webmod
using netColarUtils

**
** Server entry point
**
const class Fantomato : DraftMod
{
  static const Log log := Fantomato#.pod.log
  static const GlobalSettings settings := GlobalSettings.load
  static const Cache cache := Cache()
  static const SitemapGen sitemap := SitemapGen()
  static const TagsActor tagger :=TagsActor()

  ** Constructor.
  new make()
  {
    pubDir = null
    logDir = `./log/`.toFile
    router = Router {
      routes = [
        // Admin
        Route("/_admin", "GET", AdminWeblet#index),
        Route("/{ns}/_admin", "GET", AdminWeblet#index),
        Route("/_adminLogin", "POST", AdminWeblet#login),
        Route("/{ns}/_adminLogin", "POST", AdminWeblet#login),
        Route("/_/keepAlive", "GET", AdminWeblet#keepAlive),
        Route("/{ns}/_/keepAlive", "GET", AdminWeblet#keepAlive),
        Route("/_/nsPages", "POST", AdminWeblet#namespacePages),
        Route("/{ns}/_/nsPages", "POST", AdminWeblet#namespacePages),
        Route("/_/nsFiles", "POST", AdminWeblet#namespaceFiles),
        Route("/{ns}/_/nsFiles", "POST", AdminWeblet#namespaceFiles),
        Route("/_/pageText", "POST", AdminWeblet#pageText),
        Route("/{ns}/_/pageText", "POST", AdminWeblet#pageText),
        Route("/_/save", "POST", AdminWeblet#save),
        Route("/{ns}/_/save", "POST", AdminWeblet#save),
        Route("/_/nsComments", "POST", AdminWeblet#namespaceComments),
        Route("/{ns}/_/nsComments", "POST", AdminWeblet#namespaceComments),
        Route("/_/nsOptions", "POST", AdminWeblet#namespaceOptions),
        Route("/{ns}/_/nsOptions", "POST", AdminWeblet#namespaceOptions),
        Route("/_/refreshTags", "POST", AdminWeblet#refreshTags),
        Route("/{ns}/_/refreshTags", "POST", AdminWeblet#refreshTags),
        Route("/_/remove", "POST", AdminWeblet#remove),
        Route("/{ns}/_/remove", "POST", AdminWeblet#remove),
        Route("/_/rename", "POST", AdminWeblet#rename),
        Route("/{ns}/_/rename", "POST", AdminWeblet#rename),
        Route("/_/newPage", "POST", AdminWeblet#newPage),
        Route("/{ns}/_/newPage", "POST", AdminWeblet#newPage),
        Route("/_/upload", "POST", AdminWeblet#upload),
        Route("/{ns}/_/upload", "POST", AdminWeblet#upload),

        // End Admin

        Route("/_/captcha", "GET", CommentsWeblet#captcha),
        Route("/{ns}/_/captcha", "GET", CommentsWeblet#captcha),
        Route("/_/comments", "GET", CommentsWeblet#comments),
        Route("/{ns}/_/comments", "GET", CommentsWeblet#comments),
        Route("/_/commentAdd", "POST", CommentsWeblet#addComment),
        Route("/{ns}/_/commentAdd", "POST", CommentsWeblet#addComment),
        Route("/_tag", "GET", PageWeblet#tag),
        Route("/{ns}/_tag", "GET", PageWeblet#tag),
        // "index" routes to "home"
        Route("/", "GET", PageWeblet#page),
        // file items
        Route("/files/*", "GET", #serveFileItem),
        Route("/{namespace}/files/*", "GET", #serveFileItem),
        // template items
        Route("/tpl/*", "GET", #serveTplItem),
        Route("/{namespace}/tpl/*", "GET", #serveTplItem),
        // page items
        // note that it will also map root files request such as /robots.txt
        Route("/{page}", "GET", PageWeblet#page),
        Route("/{namespace}/{page}", "GET", PageWeblet#page),
      ]
    }

    tagger.send("run")
    sitemap.send("run")
  }

  Void serveFileItem(Str:Str args)
  {
    ns := (args["namespace"] ?: req.session["fantomato.ns"]) ?: "default"
    i := args.containsKey("namespace") ? 2 : 1
    path := req.uri.path[i .. -1].join("/")
    uri := `$ns/files/$path`
    serveFile(uri, res)
  }

  Void serveRootFile(Str:Str args)
  {
    ns := (args["namespace"] ?: req.session["fantomato.ns"]) ?: "default"
    i := args.containsKey("namespace") ? 1 : 0
    path := req.uri.path[i .. -1].join("/")
    uri := `$ns/files/$path`
    serveFile(uri, res)
  }

  Void serveTplItem(Str:Str args)
  {
    tpl := req.session["fantomato.tpl"] ?: "default"
    i := args.containsKey("namespace") ? 2 : 1
    path := req.uri.path[i .. -1].join("/")
    uri := `tpl/$tpl/$path`
    // If a file is not present in a custom namepace template, get it from default template
    // This allow overriding only a few files in custm templates
    if( ! (GlobalSettings.root + uri).exists)
      uri = `tpl/default/$path`
    serveFile(uri, res)
  }

  ** Serve files from data folder
  static Void serveFile(Uri path, WebRes res)
  {
    file := GlobalSettings.root + path

    // Safety check
    // could use normalize too but then symlink break ... alow or not ?
    if( ! file.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      file404(res); return
    }

    if(! file.exists)
    {
      file404(res); return
    }
    FileWeblet(file).onGet
  }

  static Void file404(WebRes res)
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 404
    res.out.close
    return
  }

  static Void sendJson(WebRes res, Obj obj, Int statusCode := 200)
  {
    res.headers["Content-Type"] = "application/json"
    res.statusCode = statusCode
    out := res.out
    try
      JsonUtils.save(out, obj)
    finally
    out.close
  }

  static Str pageLink(Str text)
  {
    result := ""
    text.each
    {
      c := it.toChar
      if(it.isAlphaNum)
        result += c.lower
      else if(result.isEmpty || result[-1] != '_')
        result += "_"
    }
    return result
  }
}

