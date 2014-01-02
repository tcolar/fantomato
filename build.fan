
using build

**
** Build
**
class Build : BuildPod
{
  new make()
  {
    podName = "fantomato"
    meta = ["license.name" : "MIT", "vcs.uri" : "https://github.com/tcolar/fantomato"]
    summary = "Fantomato - Blog / Wiki engine. (Dokuwiki & Markdown)"
    depends = ["sys 1.0+", "draft 1.0.2+", "web 1.0+", "webmod 1.0+",
                "concurrent 1.0+", "markdown 1.0+", "netColarUtils 1.0.3+",
                "mustache 1.0+", "xml 1.0+", "captcha302 1.0.0+"]
    srcDirs = [`fan/`, `fan/util/`]
    javaDirs = [`java/`]
    version = Version("0.9.7")
  }
}