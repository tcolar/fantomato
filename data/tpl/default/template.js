// Generic/Common javascript functions

// Functions
function openAddThis(publisher)
{
  var url='http://www.addthis.com/bookmark.php?v=1&pub='+publisher+'&url='+encodeURIComponent(document.location)+'&title='+encodeURIComponent(document.title);
  window.open(url);
  return;
}

$(document).ready(function() {

  /* comment form */
  $("#addCommentLink").click(function() {
      $("#addCommentPane").toggle();
      if($("#addCommentPane").is(":visible"))
        $("#captchca").attr("src", "/captcha");
      return false;
  });

  /* Fetch comments via Ajax / Json */
  $.getJSON('/_/comments', function(data) {
    /*$.each(data.items, function(key, val) {
      items.push('<li id="' + key + '">' + val + '</li>');
    });

    $('<ul/>', {
      'class': 'my-new-list',
      html: items.join('')
    }).appendTo('body');*/
  });
});

/*function buttonHelp(text)
{
  document.getElementById("buttonHelpSpan").firstChild.nodeValue = text;
}
function toggle(objName)
{
  var obj=document.getElementById(objName);
  obj.style.display=(obj.style.display!='block')? 'block' : 'none';
}
*/

