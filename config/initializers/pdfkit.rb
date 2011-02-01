PDFKit.configure do |config|
  config.wkhtmltopdf = '/usr/local/bin/wkhtmltopdf'
  config.default_options = {
    :disable_smart_shrinking => false,
    :page_size => 'Letter',
    :print_media_type => true
  }
end
