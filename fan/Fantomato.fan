// History:
//  Jan 09 12 tcolar Creation
//

using draft
using web
using webmod

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
        Route("/_/captcha", "GET", CommentsWeblet#captcha),
        Route("/{ns}/_/captcha", "GET", CommentsWeblet#captcha),
        Route("/_/comments", "GET", CommentsWeblet#comments),
        Route("/{ns}/_/comments", "GET", CommentsWeblet#comments),
        Route("/_/commentAdd", "POST", CommentsWeblet#addComment),
        Route("/{ns}/_/commentAdd", "POST", CommentsWeblet#addComment),
        Route("/_/tag/{tag}", "GET", PageWeblet#tag),
        Route("/{ns}/_tag/{tag}", "GET", PageWeblet#tag),
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
    echo(GlobalSettings.root + uri)
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
}

