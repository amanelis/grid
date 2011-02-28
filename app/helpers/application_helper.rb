# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def tab_link_to(name, options = {}, html_options = {})
    html_options.merge!({ :id => 'current' }) if current_page?(options)
    link_to name, options, html_options
  end
  
  def sortable(column, title = nil, other_parameters = {})
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    other_parameters.merge!({:sort => column, :direction => direction})
    link_to title, other_parameters, {:class => css_class}
  end
  
  def navigation(*links)
    items = []
    links.each do |link|
      if (controller.controller_name.to_sym == link)
        items << content_tag(:li, "#{link.to_s}", :class => "active")
      else
        items << content_tag(:li, link_to("#{link.to_s}", link))
      end
    end
    content_tag :ul, items
  end
    
end
