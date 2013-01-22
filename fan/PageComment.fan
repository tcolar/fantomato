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

** Will be sent to frontend via ajax in json format
** Gives a list / subeset of comments with pagination data
@Serializable
const class PageCommentList
{
  ** total number of comments for this page
  const Int total
  ** Index of the first comment given in comments (relative to total)
  const Int first
  ** The (sub)lits of comments
  const PageComment[] comments

  new make(|This|? f) {if(f!=null) f(this)}
}