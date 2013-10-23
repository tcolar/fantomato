// History:
//  Oct 14 13 tcolar Creation
//

using web
using mustache
using concurrent

**
** AdminWeblet
**
class AdminWeblet : Weblet
{
  Void index(Str:Str args)
  {
    if(! loggedIn){
      file := GlobalSettings.root + `tpl/default/login.html`
      Str? tpl := (Str?) Cache.readCachedFile(file)?.content
      tpl = Mustache(tpl.in).render()
      res.headers["Content-Type"] = "text/html"
      res.statusCode = 200
      res.out.print(tpl).close
      return
    }

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

  Void login()
  {
    pass := GlobalSettings.adminPassword
    form := req.form
    if(pass.isEmpty){
      Fantomato.log.err("No password set for admin in fantomato.props !")
    }
    else if(form["login"] != "admin" || form["password"] != pass)
    {
      Fantomato.log.info("Admin login failed.")
      Actor.sleep(3sec)
    }
    else
    {
      req.session["fantomato.logggedAsAdmin"] = "yes"
    }
    res.redirect(`_admin`)
  }

  Void namespacePages(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsPages(ns)
    Fantomato.sendJson(res, pages)
  }

  Void namespaceComments(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsComments(ns)
    Fantomato.sendJson(res, pages)
  }

  Void namespaceFiles(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsFiles(ns)
    Fantomato.sendJson(res, pages)
  }

  Void namespaceOptions(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    ns := args["ns"] ?: "default"
    pages := AdminWeblet.listNsOptions(ns)
    Fantomato.sendJson(res, pages)
  }

  Void pageText(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    form := req.form
    page := form["page"]
    file := (GlobalSettings.root.uri + `$page`).toFile
    if(! file.exists || ! file.pathStr.startsWith(GlobalSettings.root.pathStr)){
      Fantomato.sendJson(res, "Not Found !", 404)
      return
    }
    text := file.readAllStr
    Fantomato.sendJson(res, text, 200)
  }

  Void save(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
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
  }

  Void upload(Str:Str args)
  {
    if( ! checkLoggedIn)
      return

    ns := args["ns"] ?: "default"
    mime := MimeType(req.headers["Content-Type"])
    boundary := mime.params["boundary"] ?: throw IOErr("Missing boundary param: $mime")

    // process each multi-part
    WebUtil.parseMultiPart(req.in, boundary) |headers, in|
    {
      disHeader := headers["Content-Disposition"]
      Str? name := null
      if (disHeader != null) name = MimeType.parseParams(disHeader)["filename"]
      if (name == null || name.size < 3)
      {
        // skip
        in.readAllBuf
        return
      }
      f := (GlobalSettings.root.uri+`$ns/files/$name`).toFile.normalize
      if(! f.pathStr.startsWith(GlobalSettings.root.pathStr)){
        throw Err("Invalid path")
      }
      Fantomato.log.warn("Saving uploaded file: $f.pathStr")
      out := f.out
      try
        in.pipe(out)
      finally
        out.close
    }
    res.redirect(`../_admin`)
  }

  Void remove(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    form := req.form
    type := form["type"]
    f := form["file"]
    file := (GlobalSettings.root.uri + `$f`).toFile
    if(! file.exists || ! file.pathStr.startsWith(GlobalSettings.root.pathStr)){
      Fantomato.sendJson(res, "File not found $f", 404)
      return
    }
    if(type == "page")
    {
      // Deleted  page associated files too
      conf := file.parent + `conf/${file.basename}.conf`
      if(conf.exists)
        conf.delete
      comments:= file.parent + `../comments/${file.basename}.json`
      if(comments.exists)
        comments.delete
    }
    Fantomato.log.warn("Removing $file.pathStr")
    file.delete
    Fantomato.sendJson(res, "Deleted $file")
  }

  Void newPage(Str:Str args){
    if( ! checkLoggedIn)
      return
    form := req.form
    ns := form["ns"]
    name := form["name"]
    index := name.indexr(".")
    if(index != null)
      name = Fantomato.pageLink(name[0..<index]) + name[index..-1]
    else
      name = Fantomato.pageLink(name) + ".md"
    echo("nm: $name")
    f := (GlobalSettings.root.uri + `$ns/pages/$name`).toFile
    if(f.exists)
    {
      Fantomato.sendJson(res, "There is alreday a file by that name !", 500)
      return
    }
    Fantomato.log.warn("Creating $f.pathStr")
    f.create
    out := f.out
    try
      out.print("# $f.basename\n")
    catch(Err e)
      {Fantomato.sendJson(res, e.toStr, 500); return}
    finally
      out.close
    Fantomato.sendJson(res, f.name)
  }

  Void rename(Str:Str args)
  {
    if( ! checkLoggedIn)
      return
    form := req.form
    name := form["name"]
    index := name.indexr(".")
    if(index != null)
      name = Fantomato.pageLink(name[0..<index]) + name[index..-1]
    else
      name = Fantomato.pageLink(name) + ".md"
    f := form["file"]
    file := (GlobalSettings.root.uri + `$f`).toFile
    if(! file.exists || ! file.pathStr.startsWith(GlobalSettings.root.pathStr))
    {
      Fantomato.sendJson(res, "File not found $f", 404)
      return
    }
    newFile := file.parent + `$name`
    if(newFile.exists)
    {
      Fantomato.sendJson(res, "There is alreday a file by that name !", 500)
      return
    }
    Fantomato.log.warn("Renaming $file.pathStr to $newFile.pathStr")
    file.moveTo(newFile)
    // Rename page associated files too
    conf := file.parent + `conf/${file.basename}.conf`
    if(conf.exists)
      conf.moveTo(newFile.parent + `conf/${newFile.basename}.conf`)
    comments := file.parent + `../comments/${file.basename}.json`
    if(comments.exists)
      comments.moveTo(newFile.parent + `../comments/${newFile.basename}.json`)
    Fantomato.sendJson(res, "Renamed to: $newFile.pathStr")
  }

  Void refreshTags()
  {
    if( ! checkLoggedIn)
      return
    echo("Refresh tags.")
    Fantomato.tagger.send("run")
    echo("Refreshed tags.")
  }

  Void keepAlive(){}

  Bool loggedIn(){
    req.session["fantomato.logggedAsAdmin"] != null
  }

  Bool checkLoggedIn()
  {
    if(loggedIn)
      return true
    else
    {
      Fantomato.sendJson(res, "Not Authorized (Logged-in ?)", 401)
      return false
    }
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