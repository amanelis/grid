// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Commenting this all out until we have a little more volume
// and/or I find a better way to test this out. [PS]
//$(function () {  
  //if ($('.activity').length > 0) {  
  //  setTimeout(updateActivity, 10000);  
  //}  
//});  
  
function updateActivity() {
  var after = $('.activity_item:first').attr('id')
  $.getScript('activities.js?after=' + after);
  if ($('.activity_notice').length == 0) {
	setTimeout(updateActivity, 60000);  
  }
}