function GridForm() {
  this.host = 'grid.cityvoice.com',
  this.height = '100%',
  this.width = '',
  this.auto_resize = false,
  this.frame_id = 'gridForm',
  this.form_id = '',
  this.custom_text = 'Contact Us!'
  this.initialize = function(params) {
    // Set the parameters
    for(key in params){
      this[key]=params[key];
    }
  },
  this.frame_url = function() {
		return 'http://' + this.host + '/api/v1/forms/' + this.form_id + '/get_html';
  },
  this.build_frame= function(){
    var scroll='no';
    if(this.auto_resize == false)
      scroll = 'auto';
    var src = 
      '<iframe id="'+ this.frame_id + '" height="' + this.height +
      '" allowTransparency="true" frameborder="0" scrolling="' + scroll +
      '" style="width:' + this.width + ';border:none"' +
      'src="' + this.frame_url() + '"><a href="'+ this.frame_url() +
      '" title="html form" rel="nofollow">' + this.custom_text +
      '</a></iframe>';
    console.log("%s", src);
    return src;
  },
  this.display = function() {
    document.write(this.build_frame());
  }
}