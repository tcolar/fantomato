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

  ** Constructor.
  new make()
  {

    pubDir = null
    logDir = `./log/`.toFile
    router = Router {
      routes = [
        // "index" root to "home"
        Route("/", "GET", PageWeblet#page),
        // file in default namespace (... kinda lame, draft should support subMod with paths ?)
        Route("/{namespace}/files/{file}", "GET", #serveFile),
        Route("/{namespace}/files/{a}/{file}", "GET", #serveFile),
        Route("/{namespace}/files/{a}/{b}/{file}", "GET", #serveFile),
        Route("/{namespace}/files/{a}/{b}/{c}/{file}", "GET", #serveFile),
        Route("/{namespace}/files/{a}/{b}/{c}/{d}/{file}", "GET", #serveFile),
        // page in default namespace
        Route("/{page}", "GET", PageWeblet#page),
        // file in named namespace
        Route("/{namespace}/files/{file}", "GET", #serveFile),
        // page in named namespace
        Route("/{namespace}/{page}", "GET", PageWeblet#page),
      ]
    }
  }

  ** Serve files from data folder
  Void serveFile(Str:Str args)
  {
    item := args["file"]
    if(args.containsKey("d")) item = args["d"]+"/$item"
    if(args.containsKey("c")) item = args["c"]+"/$item"
    if(args.containsKey("b")) item = args["b"]+"/$item"
    if(args.containsKey("a")) item = args["a"]+"/$item"
    ns := args["namespace"]
    file := settings.root + `$ns/files/$item`

    // Safety check
    if(file.normalize.pathStr.startsWith(settings.root.pathStr))
    {
      FileWeblet(file).onGet
    }
  }
}

** Server pod resources
const class PodMod : WebMod
{
  override Void onGet()
  {
    target := req.uri.path[1..-1].join("/")
    echo("target: $target")
    FileMod{file = Pod.of(this).file(target.toUri)}.onGet
  }
}


