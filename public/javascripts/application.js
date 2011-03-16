// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function($) {
  $('a[rel*=facebox]').facebox();
  $('.tiptip').tipTip();
})


function refresh_accounts() {
  $.facebox.close()
  $('#loading').html('<h3><font color="green">Loading accounts... This could take about 5 minutes depending on your connection, please be patient.</font></h3>');
  window.location = "/accounts/refresh_accounts";
}

function export_accounts() {
	$.facebox.close();
  window.location = "/accounts/export";
}

function export_client_report(id) {
  var from = $("#from").val();
  var to = $("#to").val();

  from = from.split(' ').join('+');
  to = to.split(' ').join('+');

	$.facebox.close();
	url = "/accounts/" + id + "/report/client.pdf?from=" + from + "&to=" + to;

  window.location = url;
}

function confirm_export_accounts() {
  var message = '<center>This will export account data to a CSV file, continue?</center><br><center><a href="#" onClick="export_accounts();">Yes</a> or <a href="#" onClick="$.facebox.close();">No</a></center>';
  $.facebox(message);
}

function confirm_refresh_accounts() {
  var message = '<center>Refresh accounts from salesforce?<br>This will take about 5 minutes...</center><br><center><a href="#" onClick="refresh_accounts();">Yes</a> or <a href="#" onClick="$.facebox.close();">No</a></center>';
  $.facebox(message);
}

function confirm_export_report(id) {
  var message = '<center>This will export a PDF client report for previous month.<p><a href="#" onClick="export_client_report('+id+');">Yes</a> or <a href="#" onClick="$.facebox.close();">No</a></center>';
  $.facebox(message);
}


function playSound(url) {
  var message;

  // If they have support for audio
  if( Modernizr.audio && Modernizr.audio.mp3){
    message = '<center><audio preload="auto" autobuffer><source src="'+url+'" /></audio></center>';
  } else {
    // Remove the & from the URL passed in
    url = url.split('&').join('%26');
    message = '<center><embed width="240px" height="20px" type="application/x-shockwave-flash" src="./player.swf" pluginspage="http://www.adobe.com/go/getflashplayer" flashvars="loop=no&autostart=no&animation=no&soundFile='+url+'"></center>';
  }

  // show the audio
  $.facebox(message);

  if(Modernizr.audio) {
    // initialize the audiojs
    audiojs.events.ready(function(){
      audiojs.createAll();
    });
  }

  // When facebox closes, remove the mp3_player element
  $(document).bind('close.facebox', function() {
    $("#facebox_content").empty();
  });
}