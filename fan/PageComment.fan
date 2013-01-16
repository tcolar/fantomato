// History:
//  Jan 13 13 tcolar Creation
//

**
** PageComment
** Will be saved in JSON format (filename is timestamp)
**
@Serializable
const class PageComment
{
  const Str author

  const Str title

  const Str text

  const DateTime ts

  new make(|This|? f) {if(f!=null) f(this)}

  Str date()
  {
    return ts.toTimeZone(TimeZone.cur).toLocale("DD MMM YYYY h:m zzz")
  }
}