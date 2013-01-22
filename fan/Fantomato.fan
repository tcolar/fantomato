// History:
//  Jan 09 12 tcolar Creation
//

using draft
using web
using webmod
using captcha302

**
** Server entry point
**
const class Fantomato : DraftMod
{
  static const Log log := Fantomato#.pod.log
  static const GlobalSettings settings := GlobalSettings.load
  static const Cache cache := Cache()
  static const SitemapGen sitemap := SitemapGen()

  ** Constructor.
  new make()
  {
    pubDir = null
    logDir = `./log/`.toFile
    router = Router {
      routes = [
        //Route("/captcha", "GET", #captcha),
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

    sitemap.send("run")
  }

  /*Void captcha()
  {
    CaptchaGenerator g := CaptchaGenerator(CaptchaImpl{})
    code := g.toBrowser(req, res)

    echo("ok? "+g.validate(req, code.val))
  }*/

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
}

