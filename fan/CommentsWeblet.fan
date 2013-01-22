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
  ** Send a captchca to the browser
  ** Used to validate comments are not spam (or try to anyway)
  Void captcha(Str:Str args)
  {
    CaptchaGenerator g := CaptchaGenerator(CaptchaImpl{})
    code := g.toBrowser(req, res)
    // echo("ok? "+g.validate(req, code.val))
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
    fc := GlobalSettings.root + `$ns/comments//${pageName}.json`
    if(fc.exists)
    {
      // TODO: maybe provide options to control comments caching as it could get rather large
      comments := (PageComment[]?) Cache.readCachedFile(fc, "comments")?.content
      if(comments != null && ! comments.isEmpty)
      {
        start := offset
        end := offset + nbComments
        if(start >= comments.size) start = comments.size - 1
        if(end >= comments.size) end = comments.size - 1

        items := PageCommentList
        {
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

  ** send the object to the browser in JSON format and commit the response
  Void sendJson(Obj obj)
  {
    res.headers["Content-Type"] = "application/json"
    res.statusCode = 200
    out := res.out
    try
      JsonUtils.save(out, obj)
    finally
    out.close
  }
}