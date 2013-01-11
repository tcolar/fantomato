/*
------------------------------------
JavaOnTracks          Thibaut Colar
tcolar-jot AT colar DOT net
Artistic Licence 2.0
http://www.javaontracks.net
------------------------------------
 */

package net.colar.jotwiki;

import java.util.Random;

/**
 * Collection of antispam functions
 * @author thibautc
 */
public class JOTAntiSpam
{
    /**
     * Use for encoding email addresses in web pages.
     *  encode the email by using javascript, so robots can't harvest them to easily.
     */
    public static String encodeEmail(String email, boolean asLink)
    {
        String result=asLink?"javascript:window.location.replace(unescape(":"<script language=\"javascript\">document.write(unescape(";
        Random rand=new Random();
        if(email!=null && email.length()>=5)
        {
            String escaped=escape(email);
            // each escaped char should be at least 3-4 char now, so length should be > 15
            int pieces=Math.abs(rand.nextInt(3)+3);
            // cut in 3-7 pieces
            int partSize=escaped.length()/pieces;
            int x=0;
            int y=partSize;
            for(int i=0;i!=pieces;i++)
            {
                result+="\""+escaped.substring(x,y)+"\"+";
                // introduce random line feeds
                if(rand.nextBoolean()==true)
                    result+="\n";
                x+=partSize;
                y+=partSize;
            }
            result+="\""+escaped.substring(x,escaped.length())+"\"";
        }
        result+=asLink?"));":"));</script>";
        return result;
    }


    /**
     * Escape a string(email) so that javascript can read it using unescape
     * Excaping is hexadecimal value of each char
     *
     * @param email
     * @return
     */
    public static String escape(String email)
    {
        String escaped="";
        for(int i=0;i!=email.length();i++)
        {
            escaped+="%"+Integer.toHexString(email.charAt(i));
        }
        return escaped;
    }

}