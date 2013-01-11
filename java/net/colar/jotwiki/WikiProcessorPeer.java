
package fan.fantomato;

import net.colar.jotwiki.*;

public class WikiProcessorPeer
{
  public static WikiProcessorPeer make(WikiProcessor self)
  {
    return new WikiProcessorPeer();
  }

  public String process(WikiProcessor self, String text)
  {
    try
    {
      return JotWikiParser.getHtmlPage(text);
    }
    catch(Exception e) {return e.toString();}
  }
}