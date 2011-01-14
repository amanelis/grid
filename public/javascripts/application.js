// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(function() {
  setTimeout(updateActivity, 3000);
});

function updateActivity() {
  $.getScript("/keywords.js")
  setTimeout(updateActivity, 3000);
}


