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

  ** Constructor.
  new make()
  {
    pubDir = null
    logDir = `./log/`.toFile
    router = Router {
      routes = [
        Route("/favicon.ico", "GET", #serveRootFile),
        Route("/{namespace}/favicon.ico", "GET", #serveRootFile),
        Route("/robots.txt", "GET", #serveRootFile),
        Route("/{namespace}/robots.txt", "GET", #serveRootFile),
        Route("/sitemap.xml", "GET", #serveRootFile),
        Route("/{namespace}/sitemap.xml", "GET", #serveRootFile),
        // "index" root to "home"
        Route("/", "GET", PageWeblet#page),
        // file items
        Route("/files/*", "GET", #serveFileItem),
        Route("/{namespace}/files/*", "GET", #serveFileItem),
        // template items
        Route("/tpl/*", "GET", #serveTplItem),
        Route("/{namespace}/tpl/*", "GET", #serveTplItem),
        // page in default namespace
        Route("/{page}", "GET", PageWeblet#page),
        // page in named namespace
        Route("/{namespace}/{page}", "GET", PageWeblet#page),
      ]
    }
  }

  Void serveFileItem(Str:Str args)
  {
    ns := (args["namespace"] ?: req.session["fantomato.ns"]) ?: "default"
    i := args.containsKey("namespace") ? 2 : 1
    path := req.uri.path[i .. -1].join("/")
    uri := `$ns/files/$path`
    serveFile(uri)
  }

  Void serveRootFile(Str:Str args)
  {
    ns := (args["namespace"] ?: req.session["fantomato.ns"]) ?: "default"
    i := args.containsKey("namespace") ? 1 : 0
    path := req.uri.path[i .. -1].join("/")
    uri := `$ns/files/$path`
    serveFile(uri)
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
    serveFile(uri)
  }

  ** Serve files from data folder
  Void serveFile(Uri path)
  {
    file := GlobalSettings.root + path

    // Safety check
    // could use normalize too but then symlink break ... alow or not ?
    if( ! file.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      file404; return
    }

    if(! file.exists)
    {
      file404; return
    }
echo("file: $file")
    FileWeblet(file).onGet
  }

  Void file404()
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 404
    res.out.close
    return
  }
}

