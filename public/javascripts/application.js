// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function refresh_accounts() {
  jQuery.facebox.close();
  $('#loading').html('<h3><font color="green">Loading accounts... This could take about 5 minutes depending on your connection, please be patient.</font></h3>');
  window.location = "/accounts/refresh_accounts"
}

function export_accounts() {
	jQuery.facebox.close();
  window.location = "/accounts/export"
}

function export_client_report(id) {
	jQuery.facebox.close();
	url = "/accounts/" + id + "/report/client.pdf"
	window.location = url
}

function confirm_export_accounts() {
  var message = '<center>This will export account data to a CSV file, continue?</center><br><center><a href="#" onClick="export_accounts();">Yes</a> or <a href="#" onClick="jQuery.facebox.close();">No</a></center>';
  jQuery.facebox(message);
}

function confirm_refresh_accounts() {
  var message = '<center>Refresh accounts from salesforce?<br>This will take about 5 minutes...</center><br><center><a href="#" onClick="refresh_accounts();">Yes</a> or <a href="#" onClick="jQuery.facebox.close();">No</a></center>';
  jQuery.facebox(message);
}

function confirm_export_report(id) {
	var message = '<center>This will export a PDF client report for previous month.</center><br><center><a href="#" onClick="export_client_report('+id+');">Yes</a> or <a href="#" onClick="jQuery.facebox.close();">No</a></center>';
  jQuery.facebox(message);
}


