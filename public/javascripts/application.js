// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Commenting this all out until we have a little more volume
// and/or I find a better way to test this out. [PS]
//$(function () {  
  //if ($('.activity').length > 0) {  
  //  setTimeout(updateActivity, 10000);  
  //}  
//});  


$(fuction() {
	//if ($("#activities").length > 0) {
		setTimeout(updateAvtivity, 1000);
	//}
});
  
function updateActivity() {
  	$.getScript("/activities.js")
	setTimeout(updateActivity, 1000);
}