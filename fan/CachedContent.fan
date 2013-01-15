// History:
//  Jan 10 13 tcolar Creation
//

**
** CachedContent
** Data for a cached content (potentioally processed) from file
**
@Serializable
class CachedContent
{
  ** last this was read
  DateTime lastUse := DateTime.now

  ** file last modif
  DateTime ts

  const Str serialized

  ** Returns the content
  Obj content()
  {
    lastUse = DateTime.now
    return serialized.in.readObj
  }

  new make(|This|? f) {if(f != null) f(this)}

  new makeObj(Obj content, DateTime ts)
  {
    this.serialized =  Buf().writeObj(content).flip.readAllStr
    this.ts = ts
  }
}