// History:
//  Jun 26 13 tcolar Creation
//

**
** SettingGen
**
class SettingGen
{
  Void main()
  {
    root := GlobalSettings.root
    root.listDirs.findAll{(it + `pages/`).exists}.each |ns|
    {
      (ns + `pages/`).listFiles.each |page|
      {
        ext := page.ext?.lower
        if(ext!=null && ext == "md" || ext == "txt" || ext == "html")
        {
          PageSettings.loadFor(ns.name, page.basename)
          echo("$ns $page")
        }
      }
    }
  }
}