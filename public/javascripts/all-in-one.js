// JavaScript Document

// Superfish menu
$(document).ready(function(){	
    $('ul.sf-menu').superfish({ 
            delay:       800,                            // one second delay on mouseout 
            animation:   {opacity:'show',height:'show'},  // fade-in and slide-down animation 
            speed:       'fast',                          // faster animation speed 
            autoArrows:  false,                           // disable generation of arrow mark-up 
			dropShadows:   true   						// turn on drop shadows
    }); 	
});