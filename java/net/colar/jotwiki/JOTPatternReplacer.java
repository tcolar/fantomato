/**
------------------------------------
JOTWiki          Thibaut Colar
tcolar-wiki AT colar DOT net
Licence at http://www.jotwiki.net
------------------------------------
 */
package net.colar.jotwiki;

/**
 * Generic "Replacer" Object, that is used to define a replacement pattern.
 * This is an utility object used by text parsers
 * @author tcolar
 */
public class JOTPatternReplacer
{
  public static final int AUTOMATIC = -1;
  boolean encodeContent=true;
  boolean parseContent=true;
  boolean lineBreaks=true;
  boolean removeContent=false;
  String open=null;
  String close=null;
  String head="";
  String tail="";

  int encoding=JOTHTMLUtilities.ENCODE_ALL & ~ JOTHTMLUtilities.ENCODE_LINE_BREAKS;

  public JOTPatternReplacer(String open,String close)
  {
    this.open=open;
    this.close=close;
  }
  public JOTPatternReplacer(String open,String close,String head, String tail)
  {
    this.open=open;
    this.close=close;
    this.tail=tail;
    this.head=head;
  }
  public String getClose() {
    return close;
  }
  public void setClose(String close) {
    this.close = close;
  }
  public boolean isEncodeContent() {
    return encodeContent;
  }
  public void setEncodeContent(boolean encodeContent) {
    this.encodeContent = encodeContent;
  }
  public String getHead() {
    return head;
  }
  public void setHead(String head) {
    this.head = head;
  }
  public String getOpen() {
    return open;
  }
  public void setOpen(String open) {
    this.open = open;
  }
  public boolean isParseContent() {
    return parseContent;
  }
  public void setParseContent(boolean parseContent) {
    this.parseContent = parseContent;
  }
  public String getTail() {
    return tail;
  }
  public void setTail(String tail) {
    this.tail = tail;
  }
  public boolean isLineBreaks() {
    return lineBreaks;
  }
  public void setLineBreaks(boolean lineBreaks) {
    this.lineBreaks = lineBreaks;
  }
  public boolean isRemoveContent() {
    return removeContent;
  }
  public void setRemoveContent(boolean removeContent) {
    this.removeContent = removeContent;
  }

    public int getEncoding()
    {
        return encoding;
    }

    public void setEncoding(int encoding)
    {
        this.encoding = encoding;
    }

}