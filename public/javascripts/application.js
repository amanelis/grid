// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function refresh_accounts() {
  jQuery.facebox.close();
  //$('#loading').html('<p><img src="images/facebox/loading.gif" /></p>');
  $('#loading').html('<h3><font color="green">Loading accounts... This could take about 5 minutes depending on your connection, please be patient.</font></h3>');
  window.location = "/accounts/refresh_accounts"
}

function confirm_refresh_accounts() {
  var message = '<center>Refresh accounts from salesforce?</center><br><center><a href="#" onClick="refresh_accounts();">Yes</a> or <a href="#" onClick="jQuery.facebox.close();">No</a></center>';
  jQuery.facebox(message);
}


