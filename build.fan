
using build

**
** Build
**
class Build : BuildPod
{
  new make()
  {
    podName = "fantomato"
    summary = "Fantomato - Blog / Wiki engine. (Dokuwiki & Markdown)"
    depends = ["sys 1.0+", "draft 1.0+", "web 1.0+", "webmod 1.0+",
                "concurrent 1.0+", "markdown 1.0+"]
    srcDirs = [`fan/`]
    resDirs = [`css/`, `pages/`, `js/`,`img/`]
    version = Version("1.0.0")
  }
}