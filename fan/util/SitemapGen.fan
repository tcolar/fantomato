// History:
//  Jan 18 13 tcolar Creation
//

using concurrent
using xml

**
** SitemapGen : Generates Google sitemaps for all namespaces
**
const class SitemapGen : Actor
{
  new make() : super(ActorPool()) {}

  override Obj? receive(Obj? msg)
  {
    root := GlobalSettings.root
    root.listDirs.findAll{(it + `ns.conf`).exists}.each
    {
      generate(it)
    }

    // check again tomorrow
    // TODO: Update this once a proper scheduler is implemented
    sendLater(24hr, "run")

    return null
  }

  ** Generate the sitemap for a given namespace
  Void generate(File nsDir)
  {
    lastRun := nsDir + `sitemap_ts.txt`
    ts :=  lastRun.exists ? lastRun.modified : DateTime.fromJava(0)

    if(lastChange(nsDir) <= ts) // we are up to date
      return

    publicUri := NsSettings.loadFor(nsDir.name).publicUri
    if(publicUri.isEmpty)
    {
      Fantomato.log.info("Cab;t create sitemap for $nsDir.name because publicUri is not set.")
      return
    }

    sm := nsDir + `files/sitemap.xml.gz`
    out := Zip.gzipOutStream(sm.out)
    try
    {
      writeSitemap(out, nsDir, publicUri)

      // write the new timestamp only if it didn't fail
      lastRun.out.printLine(DateTime.now.toStr)
    }
    catch(Err e) {Fantomato.log.err("Sitemap generation error for ns: $nsDir.name", e)}
    finally
    {
      out.close
    }

  }

  ** Writes the sitemap(XML) to the outstream
  private Void writeSitemap(OutStream out, File nsDir, Str publicUri)
  {
    if( ! publicUri.endsWith("/"))
      publicUri += "/"
    Fantomato.log.info("Writing the sitemap for $nsDir.name")
    root := XElem("urlset").addAttr("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")

    (nsDir + `pages/`).listFiles.each |f|
    {
      if(f.name[0]!='.' && f.name[0]!='~' && f.name[-1] != '~')
      {
        prio := f.basename == "home" ? "0.8" : "0.5"
        mod := f.modified.toIso
        root.add(
          XElem("url")
          {
            XElem("loc") {XText("${publicUri}${f.basename}"),},
            XElem("lastmod") {XText(mod),},
            XElem("changefreq") {XText("daily"),},
            XElem("priority") {XText(prio),},
          }
        )
      }
    }
    XDoc(root).write(out)
  }

  ** Get timestamp of the most recently modified for the given namespace
  DateTime lastChange(File nsDir)
  {
    pages := nsDir + `pages/`
    if(! pages.exists)
      return DateTime.now
    DateTime? last
    pages.listFiles.each
    {
      if(last == null || it.modified > last)
        last = it.modified
    }
    return last == null ? DateTime.now : last
  }
}