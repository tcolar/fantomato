// History:
//  Jan 10 13 tcolar Creation
//

using netColarUtils

**
** GlobalSettings
**
@Serializable
const class GlobalSettings
{
  @Transient
  static const File etcFile := Env.cur.workDir + `etc/fantomato/fantomato.props`

  ** Not a setting (seaparate file)
  @Transient
  static const File root := readRoot

  @Transient
  static const Str adminPassword := readAdminPassword

  static File readRoot()
  {
    if(! etcFile.exists)
    {
      err := Err("Warning : $etcFile.pathStr missing ! won't run.")
      Fantomato.log.err("Error", err)
      err.trace
      throw err
    }
    dataRoot := etcFile.readProps["dataRoot"]?.trim ?: "null"

    if(! dataRoot.endsWith(File.sep))
      dataRoot = dataRoot + File.sep
    root := File.os(dataRoot)
    if( ! root.exists)
    {
      err := Err("Warning : dataRoot doesn't exist (${root.osPath})!.")
      Fantomato.log.err("Error", err)
      err.trace
      throw err
    }
    return root
  }

  static Str readAdminPassword()
  {
    if(! etcFile.exists)
    {
      err := Err("Warning : $etcFile.pathStr missing ! won't run.")
      Fantomato.log.err("Error", err)
      err.trace
      throw err
    }
    return etcFile.readProps["adminPassword"]?.trim ?: ""
  }

  static GlobalSettings load()
  {
    return (GlobalSettings) JsonSettings.load(root + `fantorepo.conf`, GlobalSettings#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}