#!/bin/bash
# Render benchmeth.txt as an HTML document
{
echo "<html>
<head>
<style type="text/css">
h1 {
        font-family: arial, geneva, helvetica, sans-serif;
        color: 000000;
        font-size: 16px;
        font-weight: bold;
        text-decoration: none; 
}
input {
        font-family: arial, geneva, helvetica, sans-serif;
        font-size: 75%;
        color: 000000;
        font-weight: normal;
        text-decoration: none; 
}
.title {
        font-family: arial, geneva, helvetica, sans-serif;
        color: 000000;
        font-size: 24px;
        font-weight: bold;
        text-decoration: none; 
}
h2 {
        font-family: arial, geneva, helvetica, sans-serif;
        color: 000000;
        font-size: 14px;
        font-weight: bold;
        text-decoration: none; 
}
.notstarted {
    background-color: #ffffff;
}
.started {
    background-color: #008080;
}
.late {
    background-color: #ff0000;
}
.done {
    background-color: #00ff00;
}
.na {
    background-color: #404040;
}
table {
        font-family: arial, geneva, helvetica, sans-serif;
        border-width: 1; 
        border-style: solid; 
        border-color: #a0a0a0; 
        background-color: #ffffff;
        font-size: 14px;
}
</style>
<script>
function shoh(id) {   
  if (document.getElementById(id)) { // DOM3 = IE5, NS6
    if (document.getElementById(id).style.display == 'none'){
      document.getElementById(id).style.display = 'block';
    } else {
      document.getElementById(id).style.display = 'none';      
    }
  } else {
    if (document.layers) {  
      if (document.id.display == 'none'){
        document.id.display = 'block';
      } else {
        document.id.display = 'none';
      }
    } else {
      if (document.all.id.style.visibility == 'hidden'){
        document.all.id.style.visibility = 'visible';
      } else {
        document.all.id.style.visibility = 'hidden';
      }
    }
  } 
}
function mark_class(obj,id,cls) {
    obj.style = 'background-color:#0000f0';
    document.getElementById(id).setAttribute('class',cls);
    document.getElementById(id).setAttribute('className',cls);
    return false;
}
function handleresp()
{
    return;
}
function put_file(fname) {
/*
 * Mozilla and WebKit
 */
if (window.XMLHttpRequest)
    req = new XMLHttpRequest();
else
if (window.ActiveXObject)
{
/*
 * Internet Explorer (new and old)
 */
    try
    {
       req = new ActiveXObject('Msxml2.XMLHTTP')
    }
    catch (e)
    {
       try
       {
           req = new ActiveXObject('Microsoft.XMLHTTP');
       }
       catch (e)
       {}
    }
}
req.open('PUT', fname, true);
req.setRequestHeader('Content-type','application/octet-stream');
req.setRequestHeader('Expect','100-Continue');
req.onreadystatechange = handleresp;
try
{
var txt = (new XMLSerializer).serializeToString(document);
}
catch(e)
{
    txt = document.xml;
}
try
{
req.send(txt);
}
catch (e)
{
    alert('Plan Save Error: ' + e)
}
return;
}
</script>
<title>E2 Systems PATH Load Testing Project Plan Template</title>
</head>
<body>
<table width='100%'><tbody>
<tr>
<td class='title'>PATH Project Plan Template</td><td width='25%' align='right'><A HREF='/'><img src='web_path_web/e2tiny.gif' alt='E2 Systems Logo' /></A></td></tr>
</tbody></table>"
$PATH_AWK 'BEGIN {
div_cnt = 1
getline
print "<H1 id=\"i0\"><input type=\"button\" value=\"Show/Hide\" onClick=\"shoh('\''div0'\'')\" />" $0 "</H1>"
print "<DIV id=\"div0\" style=\"display:none\">"
last_ind = 0
id_cnt = 1
}
{
    x=$0
    if (length == 0)
    {
        print "<HR />"
        next
    }
    for (i = 1; i < length; i++)
        if (substr($0,i,1) != " ")
            break
    x = substr($0,i)
    if (i != last_ind)
    {
        if (i > last_ind)
        {
            if (i > 3)
                print substr("            ",1, last_ind - 1) "<UL>"
        }
        else
        {
            if (last_ind > 3)
                for (j = last_ind; j > i; j -= 2)
                    print substr("            ",1, j - 3) "</UL>"
        }
    }
    if (i == 1)
    {
        print "</DIV>"
        print "<H1 id=\"i" id_cnt "\"><input type=\"button\" value=\"Show/Hide\" onClick=\"shoh('\''div" div_cnt "'\'')\" />" x "</H1>"
        print "<DIV style=\"display:none\" id=\"div" div_cnt++ "\">"
    }
    else
    if (i == 3)
        print "  <H2 id=\"i" id_cnt "\">" x "</H2>"
    else
        print substr("            ",1, i - 1) "<LI id=\"i" id_cnt "\"><input type=\"button\" value=\"N/A\" onClick=\"mark_class(self,'\''i" id_cnt "'\'','\''na'\'');\" /><input type=\"button\" value=\"Started\" onClick=\"mark_class(self,'\''i" id_cnt "'\'','\''started'\'');\" /><input type=\"button\" value=\"Late\" onClick=\"mark_class(self,'\''i" id_cnt "'\'','\''late'\'');\" /><input type=\"button\" value=\"Done\" onClick=\"mark_class(self,'\''i" id_cnt "'\'','\''done'\'');\" />" x "</LI>"
    last_ind = i
    id_cnt++
}
END {
    print "</DIV>"
    print "<table><tr><td><input type=\"button\" value=\"Save\" onClick=\"put_file('\''data/project.html'\'')\" /></td><td><input type=\"button\" value=\"Reload\" onClick=\"location.reload()\" /></td></tr></table>"
    print "</BODY></HTML>"
}' benchmeth.txt
}>benchmeth.html
