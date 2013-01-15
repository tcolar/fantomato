// History:
//  Jan 13 13 tcolar Creation
//
using netColarUtils

**
** NsSettings : Settings for a Namespace
**
@Serializable
class NsSettings
{
  @Setting{ help = ["Name of the template(folder) to use for this namespace."]}
  Str template := "default"

  @Setting{ help = ["Google analytics ID. (Empty string for none)"]}
  Str googleAnalyticsId := ""

  @Setting{ help = ["How many comments to show. (0 for disabling comments)"]}
  Int commentsPerPage := 20

  @Setting{ help = ["Variables that will be passed to the templates",
                    "For example the namespace tagline."]}
  Str:Str variables := [:]

  @Setting{ help = ["AddThis publisher ID. For page sharing, facebook likes and so on",
                    "Empty String to disable."]}
  Str addThisId := ""

  @Setting{help= ["Whether to create a table of contents for each page",
                  "Disable if you don't need / want to show a TOC."]}
  Bool enableToc := false

  // TODO: Will need to set smtp server in global conf first ?
  //@Setting{ help = ["Email address to send comments to."]}
  //Str emailCommentsTo := ""

  new make(|This| f) {f(this)}

  static NsSettings loadFor(Str ns)
  {
    File f :=  GlobalSettings.root + `$ns/ns.conf`
    cached := Cache.readCachedFile(f, "json", [NsSettings#.qname])
    return (NsSettings) (cached?.content ?: NsSettings{})
  }

  Str getGaCode()
  {
    if(googleAnalyticsId.trim.isEmpty)
      return ""
    return Str<|<!-- Begin Google Analytics -->
                <script type="text/javascript">
                var _gaq = _gaq || [];

                _gaq.push(['_setAccount', '|>
    + googleAnalyticsId +
     Str<|']);
          _gaq.push(['_trackPageview']);

          (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
          })();
          </script>
          <!-- End Google Analytics -->
|>
  }
}