// History:
//  Jan 13 13 tcolar Creation
//

**
** PageComment
** Will be saved in JSON format (filename is timestamp)
**
@Serializable
class PageComment
{
  Str author

  Str title

  Str text

  new make(Str author, Str title, Str text)
  {
    this.author = author
    this.title = title
    this.text = text
  }

  /*Void save(Str namespace, Str pageName)
  {
    // TODO
  }*/

  //File f := GlobalSettings.root + `$ns/pages/${page}/comments/*`
}