/*
------------------------------------
JavaOnTracks          Thibaut Colar
tcolar-jot AT colar DOT net
Artistic Licence 2.0
http://www.javaontracks.net
------------------------------------
 */
package net.colar.jotwiki;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utilities for HTML processing
 * @author thibautc
 */
public class JOTHTMLUtilities
{
  public static final int ENCODE_HTML_CHARS = 1;
  public static final int ENCODE_LINE_BREAKS=2;
  public static final int ENCODE_SYMBOLS=4;
  public static final int ENCODE_CURLEYS=8;
  public static final int ENCODE_ALL=16383;

  private static final int PATTERN_FLAGS_MULTI=Pattern.CASE_INSENSITIVE | Pattern.DOTALL | Pattern.MULTILINE | Pattern.CANON_EQ;
  private static final Pattern PATTERN_LINE_BREAKS=Pattern.compile("\n",PATTERN_FLAGS_MULTI);

        /**
         * Encode a text into HTML, ie: process & > < lineBreaks symbols etc...
         * This methods converts everyhting it can.
         * @param text
         * @return
         */
  public static String textToHtml(String text)
  {
    //do curleys before chars
    return textToHtml(text, ENCODE_ALL);
  }

        /**
         * Encode a text into HTML, converting only what requested using the flags.
         * falgs example: ENCODE_LINE_BREAKS | ENCODE_CURLEYS
         * @param text
         * @param flags
         * @return
         */
  public static String textToHtml(String text, int flags)
  {
    //JOTLogger.log(JOTLogger.DEBUG_LEVEL, JOTHTMLUtilities.class, "Replacing chars for.");

    if((flags & ENCODE_HTML_CHARS)>0)
    {
      text=text.replaceAll("&", "&amp;");
      text=text.replaceAll("<", "&lt;");
      text=text.replaceAll(">", "&gt;");
    }

    if((flags & ENCODE_SYMBOLS)>0)
    {
      text=doSymbols(text);
    }
    if((flags & ENCODE_LINE_BREAKS)>0)
    {
      text=doLineBreaks(text);
    }
    return text;
  }


  private static String doLineBreaks(String page)
  {
    // REPLACE CARRIAGE RETURNS BY <BR>
    Matcher m=PATTERN_LINE_BREAKS.matcher(page);
    StringBuffer buf=new StringBuffer();
    while(m.find())
    {
      JotWikiParser.safeAppendReplacement(m,buf,"<br/>\n");
    }
    m.appendTail(buf);
    page=buf.toString();
    return page;
  }

  public static String doSymbols(String s)
  {
    //sepcial symbols
    s=s.replaceAll("\\(c\\)", "&copy;");
    s=s.replaceAll("\\(tm\\)", "&trade;");
    s=s.replaceAll("\\(r\\)", "&reg;");
    // real symbols
    s=s.replaceAll("�", "&copy;");
    s=s.replaceAll("�", "&trade;");
    s=s.replaceAll("�", "&reg;");
    // currencies
    s=s.replaceAll("�", "&yen;");
    s=s.replaceAll("�", "&euro;");
    s=s.replaceAll("�", "&pound;");
    s=s.replaceAll("�", "&cent;");
    s=s.replaceAll("�", "&curren;");
    // punctuations,quotes etc ..
    s=s.replaceAll("�", "&ldquo;");
    s=s.replaceAll("�", "&rdquo;");
    s=s.replaceAll("�", "&sbquo;");
    s=s.replaceAll("�", "&rsquo;");
    s=s.replaceAll("�", "&iexcl;");
    s=s.replaceAll("�", "&bdquo;");
    s=s.replaceAll("�", "&brkbar;");
    s=s.replaceAll("�", "&ordf;");
    s=s.replaceAll("�", "&laquo;");
    s=s.replaceAll("�", "&raquo;");
    s=s.replaceAll("�", "&lsaquo;");
    s=s.replaceAll("�", "&rsaquo;");
    s=s.replaceAll("�", "&middot;");
    s=s.replaceAll("�", "&mdash;");
    s=s.replaceAll("�", "&ndash;");
    // symbols
    s=s.replaceAll("�", "&dagger;");
    s=s.replaceAll("�", "&Dagger;");
    s=s.replaceAll("�", "&sect;");
    s=s.replaceAll("�", "&para;");
    // math
    s=s.replaceAll("�", "&deg;");
    s=s.replaceAll("�", "&plusmn;");
    s=s.replaceAll("�", "&sup1;");
    s=s.replaceAll("�", "&sup2;");
    s=s.replaceAll("�", "&sup3;");
    s=s.replaceAll("�", "&ordm;");
    s=s.replaceAll("�", "&frac14;");
    s=s.replaceAll("�", "&frac12;");
    s=s.replaceAll("�", "&frac34;");
    s=s.replaceAll("�", "&divide;");
    s=s.replaceAll("�", "&micro;");
    s=s.replaceAll("�", "&not;");
    s=s.replaceAll("�", "&permil;");

    // single accents
    s=s.replaceAll("�", "&cedil;");
    s=s.replaceAll("�", "&acute;");
    s=s.replaceAll("�", "&macr;");
    s=s.replaceAll("�", "uml;");

    // lowercase accents
    s=s.replaceAll("�", "&agrave;");
    s=s.replaceAll("�", "&aacute;");
    s=s.replaceAll("�", "&aacirc;");
    s=s.replaceAll("�", "&atilde;");
    s=s.replaceAll("�", "&auml;");
    s=s.replaceAll("�", "&aring;");
    s=s.replaceAll("�", "&aelig;");
    s=s.replaceAll("�", "&egrave;");
    s=s.replaceAll("�", "&eacute;");
    s=s.replaceAll("�", "&eacirc;");
    s=s.replaceAll("�", "&euml;");
    s=s.replaceAll("�", "&igrave;");
    s=s.replaceAll("�", "&iacute;");
    s=s.replaceAll("�", "&iacirc;");
    s=s.replaceAll("�", "&iuml;");
    s=s.replaceAll("�", "&ograve;");
    s=s.replaceAll("�", "&oacute;");
    s=s.replaceAll("�", "&oacirc;");
    s=s.replaceAll("�", "&otilde;");
    s=s.replaceAll("�", "&ouml;");
    s=s.replaceAll("�", "&ugrave;");
    s=s.replaceAll("�", "&uacute;");
    s=s.replaceAll("�", "&uacirc;");
    s=s.replaceAll("�", "&uuml;");
    s=s.replaceAll("�", "&yacute;");
    s=s.replaceAll("�", "&yuml;");
    // uppercase accents
    s=s.replaceAll("�", "&Agrave;");
    s=s.replaceAll("�", "&Aacute;");
    s=s.replaceAll("�", "&Aacirc;");
    s=s.replaceAll("�", "&Atilde;");
    s=s.replaceAll("�", "&Auml;");
    s=s.replaceAll("�", "&Aring;");
    s=s.replaceAll("�", "&AElig;");
    s=s.replaceAll("�", "&Egrave;");
    s=s.replaceAll("�", "&Eacute;");
    s=s.replaceAll("�", "&Eacirc;");
    s=s.replaceAll("�", "&Euml;");
    s=s.replaceAll("�", "&Igrave;");
    s=s.replaceAll("�", "&Iacute;");
    s=s.replaceAll("�", "&Iacirc;");
    s=s.replaceAll("�", "&Iuml;");
    s=s.replaceAll("�", "&Ograve;");
    s=s.replaceAll("�", "&Oacute;");
    s=s.replaceAll("�", "&Oacirc;");
    s=s.replaceAll("�", "&Otilde;");
    s=s.replaceAll("�", "&Ouml;");
    s=s.replaceAll("�", "&Ugrave;");
    s=s.replaceAll("�", "&Uacute;");
    s=s.replaceAll("�", "&Uacirc;");
    s=s.replaceAll("�", "&Uuml;");
    s=s.replaceAll("�", "&Yacute;");
    // other foreign
    s=s.replaceAll("�", "&Ccedil;");
    s=s.replaceAll("�", "&ccedil;");
    s=s.replaceAll("�", "&iquest;");
    s=s.replaceAll("�", "&ETH;");
    s=s.replaceAll("�", "&eth;");
    s=s.replaceAll("�", "&Ntilde;");
    s=s.replaceAll("�", "&ntilde;");
    s=s.replaceAll("�", "&Ntimes;");
    s=s.replaceAll("�", "&Oslash;");
    s=s.replaceAll("�", "&oslash;");
    s=s.replaceAll("�", "&THORN;");
    s=s.replaceAll("�", "&thorn;");
    s=s.replaceAll("�", "&szlig");

    return s;
  }

  public static String doCurleys(String s)
  {
    s=s.replaceAll("'", "&#8217;");
    s=s.replaceAll("\"(.*)\"", "&#8220;$1&#8221;");
    return s;
  }

        /**
         * Straight quotes
         * @param s
         * @return
         */
  public static String doStraight(String s)
  {
    s=s.replaceAll("\"", "&quot;");
    s=s.replaceAll("�", "&lsquo;");
    return s;
  }

}