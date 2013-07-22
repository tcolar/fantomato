// History:
//  Jun 26 13 tcolar Creation
//
using concurrent

**
** TagsActor
** Create an in memory map of pages per unique tag
** This would not scale to a huge number of pages, but it's fast and simple
** If ever needed we could use mongo, couch or whatever.
**
const class TagsActor : Actor
{
  new make() : super(ActorPool()) {}

  override Obj? receive(Obj? msg)
  {
    try
    {
      if(msg == "run")
      {
        // index or update index of page tags
        // not that currently tags don't get removed until a restart
        Str:TaggedPage[] map := [:]
        if(Actor.locals.containsKey("fantomato.tags"))
          map = (Str:TaggedPage[]) Actor.locals["fantomato.tags"]

        root := GlobalSettings.root
        root.listDirs.findAll{(it + `pages/conf/`).exists}.each
        {
          indexTags(map, it)
        }

        Actor.locals["fantomato.tags"] = map
      }
      else if(msg == "tags")
      {
        // return all tags and their count
        Str:Int tags := [:] {ordered = true}
        map := (Str:TaggedPage[]) Actor.locals["fantomato.tags"]
        map.keys.sort.each |key|
        {
          tags[key] = map[key].size
        }
        return tags// todo : sort ?
      }
      else if(msg is List)
      {
        list := msg  as Str[]
        if(list[0] == "tag")
        {
          map := (Str:TaggedPage[]) Actor.locals["fantomato.tags"]
          return map[list[1]]
        }
      }
    }
    catch(Err e) {e.trace}
    return null
  }

  ** Generate the sitemap for a given namespace
  Void indexTags(Str:TaggedPage[] map, File nsDir)
  {
    ns := nsDir.name
    conf := nsDir + `pages/conf/`
    conf.listFiles.each
    {
      page := it.basename
      indexPage(map, ns, page)
    }
  }

  Void indexPage(Str:TaggedPage[] map, Str ns, Str page)
  {
    try
    {
      settings := PageSettings.loadFor(ns, page)
      settings.tags.each
      {
        tag := it
        echo("adding $ns $page for tag $tag")
        if(map.containsKey(tag))
        {
          tp := TaggedPage{it.ns = ns; it.page = page}
          if( !  map[tag].contains(tp))
            map[tag].add(tp)
        }
        else
          map[tag] = [TaggedPage{it.ns = ns; it.page = page}]
      }
    }
    catch(Err e){}
  }
}

@Serializable
const class TaggedPage
{
  new make(|This| f) {f(this)}

  override Bool equals(Obj? that)
  {
    other := that as TaggedPage
    return other.ns == this.ns && other.page == this.page
  }

  Str link()
  {
    return /*(ns == "default" ? "" : "/$ns") +*/"/$page"
  }

  const Str ns
  const Str page
}