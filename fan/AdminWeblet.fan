// History:
//  Oct 14 13 tcolar Creation
//

using web
using mustache

**
** AdminWeblet
**
class AdminWeblet : Weblet
{
  Void index(Str:Str args)
  {
    file := GlobalSettings.root + `tpl/default/admin.html`
    Str? tpl := (Str?) Cache.readCachedFile(file)?.content
    params := Str:Obj[:]
    params["namespaces"] = AdminWeblet.listNamespaces()
    params["ns"] = args["ns"] ?: "default"
    tpl = Mustache(tpl.in).render(params)
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200
    res.out.print(tpl).close
  }

  Void namespacePages(Str:Str args)
  {
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsPages(ns)
    Fantomato.sendJson(res, pages)
    return
  }

  Void namespaceComments(Str:Str args)
  {
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsComments(ns)
    Fantomato.sendJson(res, pages)
    return
  }

  Void namespaceFiles(Str:Str args)
  {
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsFiles(ns)
    Fantomato.sendJson(res, pages)
    return
  }

  Void namespaceOptions(Str:Str args)
  {
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsOptions(ns)
    Fantomato.sendJson(res, pages)
    return
  }

  Void pageText(Str:Str args)
  {
    form := req.form
    page := form["page"]
    file := (GlobalSettings.root.uri + `$page`).toFile
    if(! file.exists || ! file.pathStr.startsWith(GlobalSettings.root.pathStr)){
      Fantomato.sendJson(res, "Not Found !", 404)
      return
    }
    text := file.readAllStr
    Fantomato.sendJson(res, text, 200)
    return
  }

  Void save(Str:Str args)
  {
    form := req.form
    page := form["page"]
    content := form["content"]
    if(page.isEmpty){
      Fantomato.sendJson(res, "Target page unknown !", 500)
      return
    }
    file := (GlobalSettings.root.uri + `$page`).toFile
    if(! file.exists || ! file.pathStr.startsWith(GlobalSettings.root.pathStr)){
      Fantomato.sendJson(res, "File not found $file", 404)
      return
    }
    out := file.out
    try
      out.print(content)
    catch(Err e)
      {Fantomato.sendJson(res, e.toStr, 500); return}
    finally
      out.close
    now := Time.now.toLocale
    Fantomato.sendJson(res, "Saved at $now")
    return
  }

  Void refreshTags()
  {
    echo("Refresh tags.")
    Fantomato.tagger.send("run")
    echo("Refreshed tags.")
  }

  static Str[] listNamespaces()
  {
    results := Str[,]
    GlobalSettings.root.listDirs.each |File f|
    {
      if((f + `ns.conf`).exists())
      {
        results.add(f.name)
      }
    }
    return results.sort
  }

  static Str[] listNsPages(Str ns)
  {
    results := Str[,]
    dir := (GlobalSettings.root + `$ns/pages/`).normalize
    // Safety check
    if( ! dir.exists || ! dir.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      return results
    }

    dir.listFiles.each |File f|
    {
      if(f.ext?.lower == "md" || f.ext?.lower == "txt" || f.ext?.lower == "html")
      {
        results.add(f.name)
      }
    }
    return results.sort
  }

  static Str[] listNsOptions(Str ns)
  {
    results := Str[,]
    dir := (GlobalSettings.root + `$ns/pages/conf/`).normalize
    // Safety check
    if( ! dir.exists || ! dir.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      return results
    }

    dir.listFiles.each |File f|
    {
      echo(f)
      if(f.ext?.lower == "conf")
      {
        results.add(f.name)
      }
    }
    return results.sort
  }

  static Str[] listNsComments(Str ns)
  {
    results := Str[,]
    dir := (GlobalSettings.root + `$ns/comments/`).normalize
    // Safety check
    if( ! dir.exists || ! dir.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      return results
    }

    files := File[,]
    dir.listFiles.each |File f|
    {
      if(f.ext?.lower == "json")
      {
        files.add(f)
      }
    }
    // Sort newest comments first
    files.sort |f1, f2 -> Int|
    {
      return f2.modified <=> f1.modified
    }.each
    {
      results.add(it.name)
    }
    return results
  }

  static Str[] listNsFiles(Str ns)
  {
    results := Str[,]
    dir := (GlobalSettings.root + `$ns/files/`).normalize
    // Safety check
    if( ! dir.exists || ! dir.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      return results
    }

    dir.walk |File f|
    {
      if( ! f.isDir){
        nm := f.uri.relTo(dir.uri)
        results.add(nm.toStr)
      }
    }
    return results.sort
  }
}