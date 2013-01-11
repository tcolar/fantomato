// History:
//  Jan 10 13 tcolar Creation
//

using netColarUtils

**
** GlobalSettings
**
const class GlobalSettings
{
  static const File standard := Env.cur.workDir + `etc/fantomato/fantomato.props`

  static GlobalSettings load(File file := standard)
  {
    if(! file.exists)
    {
      Fantomato.log.err("Warning : $file.pathStr missing ! won't run.")
    }
    return (GlobalSettings) SettingUtils.load(file, GlobalSettings#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    if(! dataRoot.endsWith(File.sep))
      dataRoot = dataRoot + File.sep
    root = File.os(dataRoot).normalize
  }

  @Setting{ help = ["Folder where all the data will go."] }
  const Str dataRoot

 ** Transient root as normalized file
  @Transient const File root
}