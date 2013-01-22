// History:
//  Jan 21 13 tcolar Creation
//

using web
using captcha302
using netColarUtils

**
** CommentsWeblet
** Handle comments requests
**
class CommentsWeblet  : Weblet
{
  CaptchaGenerator gen := CaptchaGenerator(CaptchaImpl{})

  ** Send a captchca to the browser
  ** Used to validate comments are not spam (or try to anyway)
  Void captcha(Str:Str args)
  {
    gen.toBrowser(req, res)
  }

  ** Will send the comments for the current page
  ** Called via Ajax
  ** It relies on ns and page being in the session, whihc should be ok since comments are always in context of a page
  ** If the session expires, pagination might stop working but we coud juts do a page reload then
  ** The offset can be used for pagination
  Void comments(Str:Str args)
  {
    offset := req.uri.query["offset"]?.toInt ?: 0
    ns := req.session["fantomato.ns"]
    pageName := req.session["fantomato.page"]

    if(ns == null || pageName == null)
    {
      sendJson([,])
    }

    nsSettings := NsSettings.loadFor(ns)
    pageOpts := PageSettings.loadFor(ns, pageName)

    nbComments := nsSettings.commentsPerPage
    fc := GlobalSettings.root + `$ns/comments/${pageName}.json`
    if(fc.exists)
    {
      // TODO: maybe provide options to control comments caching as it could get rather large
      comments := (PageComment[]?) Cache.readCachedFile(fc, "comments")?.content
      if(comments != null && ! comments.isEmpty)
      {
        start := offset
        end := offset + nbComments
        if(start > comments.size) start = comments.size
        if(end > comments.size) end = comments.size

        items := PageCommentList
        {
          it.pageSize = nbComments
          it.first = offset
          it.total = comments.size
          it.comments = comments[start ..< end]
        }
        sendJson(items)
        return
      }
    }
    sendJson([,])
  }

  ** Post a comment
  Void addComment(Str:Str args)
  {
    ns := req.session["fantomato.ns"]
    pageName := req.session["fantomato.page"]
    if(ns == null || pageName == null)
    {
      sendJson("Session as timed out. Save your text and reload the page.", 500)
      return
    }
    if( ! PageSettings.loadFor(ns, pageName).commentsEnabled)
    {
      sendJson("Comments are not allowed on this page.", 500)
      return
    }

    form := req.form
    if( ! gen.validate(req, form["captcha"] ?: ""))
    {
      sendJson("Captcha code does not match.", 401)
      return
    }

    comment := PageComment
    {
      it.author = form["author"]
      it.title = form["title"]
      it.text = form["text"]
      it.ts = DateTime.now
    }

    // Add the comment to file via an actor message to be safe
    Fantomato.cache.send(["addComment", ns, pageName, comment])

    sendJson("Success", 200)
  }


  ** send the object to the browser in JSON format and commit the response
  private Void sendJson(Obj obj, Int statusCode := 200)
  {
    res.headers["Content-Type"] = "application/json"
    res.statusCode = statusCode
    out := res.out
    try
      JsonUtils.save(out, obj)
    finally
    out.close
  }
}