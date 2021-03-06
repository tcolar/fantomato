// History:
//  Jan 13 13 tcolar Creation
//

using concurrent
using netColarUtils
using markdown

**
** Cache
**
const class Cache : Actor
{
  new make() : super(ActorPool{maxThreads = 1}) {}

  override Obj? receive(Obj? msg)
  {
    list := msg as List
    action := list[0]

    if(action == "readCachedFile")
    {
      name := list[2]
      if(name == "read")
        return _readCachedFile(list[1], readProcess, [,])
      else if(name == "json")
        return _readCachedFile(list[1], jsonProcess, list[3])
      else if(name == "parse")
        return _readCachedFile(list[1], parseProcess, list[3])
      else if(name == "comments")
        return _readCachedFile(list[1], readComments, [,])

      throw Err("Unexpected process name: ${name}")
    }
    else if(action == "addComment")
      addComment(list[1], list[2], list[3])
    return null
  }

  ** Add a page comment
  private Void addComment(Str ns, Str page, PageComment comment)
  {
    fc := GlobalSettings.root + `$ns/comments/${page}.json`
    if( ! fc.exists)
      fc.create
    buf := fc.readAllBuf
    out := fc.out
    try
    {
      JsonUtils.save(out, comment, false)
      out.printLine
      out.writeBuf(buf)
    }
    finally
      out.close
  }

  ** Read a file and lazy cache the content as needed
  ** Will reload it if timestamp changes
  ** Default process is to cache the whole file content as a string
  private CachedContent? _readCachedFile(Str filePath, |File, Str[]-> Obj?| process, Str[] params)
  {
    file := File.os(filePath)
    if(! Actor.locals.containsKey("fantomato.cache"))
      Actor.locals["fantomato.cache"] = Str:CachedContent[:]
    map := Actor.locals["fantomato.cache"] as Str:CachedContent

    cached := map[file.osPath]

    if(cached == null || file.modified > cached.ts)
    {
      if(!file.exists)
      {
        echo("Not found: $file")
        return null
      }

      Fantomato.log.info("Caching : $file.osPath")
      content := process(file, params)
      if(content != null)
      {
        cached = CachedContent.makeObj(content, file.modified)
        map[file.osPath] = cached
      }
      else
        Fantomato.log.err("Got null content for $file.osPath !")
    }
    return cached
  }

  static CachedContent? readCachedFile(File file, Str processName := "read", Str[] params := [,])
  {
    Fantomato.cache.send(["readCachedFile", file.pathStr, processName, params]).get
  }

  private static const |File, Str[] -> CachedContent?| readProcess :=
      |File f, Str[] params -> Obj| {return f.readAllStr}

  private static const |File, Str[] -> CachedContent?| jsonProcess :=
  |File f, Str[] params -> Obj| {
    type := Type.find(params[0]) ?: throw Err("Type not found : ${params[0]} !")
    return JsonSettings.load(f, type)
  }

  private static const |File, Str[] -> CachedContent?| parseProcess :=
  |File f, Str[] params -> Obj| {
    content := f.readAllStr

    if(f.ext == "md")
    {
      // convert Markdown to Html
      content = Markdown().markdown(content)
    }
    else if(f.ext == "txt")
    {
      // jotwiki format
      content = WikiProcessor().process(content)
    }
    return content
  }

  private static const |File, Str[] -> CachedContent?| readComments :=
  |File f, Str[] params -> Obj| {
    in := f.in
    PageComment[] comments := [,]
    try
    {
      while(true)
        comments.add(JsonUtils.load(in, PageComment#, false))
    }
    catch(ParseErr e){}
    finally
      in.close
    return comments
  }
}