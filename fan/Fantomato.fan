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
    ns := args["namespace"] ?: "default"
    i := args.containsKey("namespace") ? 2 : 1
    path := req.uri.path[i .. -1].join("/")
    uri := `$ns/files/$path`
    serveFile(uri)
  }

  Void serveTplItem(Str:Str args)
  {
    ns := args["namespace"] ?: "default"
    i := args.containsKey("namespace") ? 2 : 1
    path := req.uri.path[i .. -1].join("/")
    uri := `tpl/$ns/$path`
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
    if(file.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      FileWeblet(file).onGet
    }
  }
}

