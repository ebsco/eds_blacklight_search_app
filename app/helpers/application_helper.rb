module ApplicationHelper

  def eds_links(options={})
    links = []
    options[:value].map do |link|
      url = link['url']
      target = '_blank'
      label = link['label']
      if url == 'detail'
        url = '#'
        target = nil
        label = 'Please log in to view ' + label
      end
      links = link_to(label, url, target: target)
    end
    links.to_s
  end

end