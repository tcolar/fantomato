// History:
//  Jan 10 13 tcolar Creation
//

**
** CachedPage
** Data for a cached page
**
const class CachedPage
{
  ** page file last modif
  const DateTime ts

  ** content
  const Str text

  new make(Str text, DateTime ts)
  {
    this.text = text
    this.ts = ts
  }
}