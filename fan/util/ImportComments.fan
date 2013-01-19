// History:
//  Jan 15 13 tcolar Creation
//

using netColarUtils

**
** convert
** one time script to convert from jotwiki comments to fantomato
**
class ImportComments
{
  Void main()
  {
    File root := `/tmp/jotwiki/data/`.toFile
    root.listDirs.each |ns|
    {
      comments := ns + `comments/`
      if(comments.exists)
      {
        comments.listDirs.each |page|
        {
          echo("$ns.name $page.name")
          PageComment[] results := [,]
          page.listFiles.sort |a, b| { -(a.name <=> b.name)}.each |file|
          {
            lines := file.readAllLines
            date := lines[0][6 .. -1].trim
            author := lines[1][8 .. -1].trim
            title := lines[2][7 .. -1].trim
            text := lines[3][6 .. -1] + "\n" + lines[4 .. -1].join("\n")

            c := PageComment
            {
              it.author = author
              it.title = title
              it.text = text
              it.ts = DateTime.fromLocale(date, "M/D/YYYY h:m")
            }

            results.add(c)
          }

          out := (comments + `${page.name}.json`).out
          results.each
          {
            JsonUtils.save(out, it, false)
            out.printLine
          }
          out.close
        }
      }
    }
  }
}