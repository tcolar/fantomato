// History:
//  Jan 13 13 tcolar Creation
//

using netColarUtils

**
** PageSettings
**
@Serializable
class PageSettings
{
  @Setting{help=["Whether this page should allow comments or not",
                 "If the namespace does allow them"]}
  Bool commentsEnabled := true

  @Setting{help = ["What template page to use to render that page",
                   "This way you could have a special template say for blog pages VS wiki pages etc ..."]}
  Str page := "page.html"

  @Setting{help=[" Who last edited the page"]} Str author := "admin"

  @Setting{help = ["Extra variables that will be passed to the templates.",
                   "For example keyword metadata."]}
  Str:Str variables := [:]

  @Setting{help = ["Tags for this page"]}
  Str[] tags := [,]

  new make(|This| f) {f(this)}

  static PageSettings loadFor(Str ns, Str page)
  {
    commentsOn := NsSettings.loadFor(ns).commentsEnabled

    File f := GlobalSettings.root + `$ns/pages/conf/${page}.conf`
    cached := Cache.readCachedFile(f, "json", [PageSettings#.qname])
    return (PageSettings) (cached?.content ?: PageSettings{commentsEnabled = commentsOn})
  }
}