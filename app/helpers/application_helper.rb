require 'cgi'

module ApplicationHelper

  def eds_links(options={})
    links = []
    options[:value].map do |link|
      url = link['url']
      target = '_blank'
      label = link['label']
      type = link['type']
      case type
        when 'pdf', 'ebook-pdf', 'ebook-epub', 'html', 'cataloglink'
          if url == 'detail' || current_or_guest_user.guest
            url = '/users/sign_in'
            target = '_self'
            label = 'Access is available, login to view'
          end
          links = link_to(label, url, target: target)
        else
          # do nothing
      end
    end
    if links.empty?
      'None available'
      else
        links.to_s
    end
  end

  def doi_link(options={})
    doi = options[:value].first
    url = 'https://doi.org/' + doi.to_s
    link_to( url, url, target: '_blank')
  end

  def html_fulltext(options={})
    data = CGI.unescapeHTML options[:value].first
    data.gsub!('<anid>','<anid style="display: none">')
    data.gsub!('<title ','<div ')
    data.gsub!('</title>','</div>')
    data.gsub!('<bold>','<b>')
    data.gsub!('</bold>','</b>')
    data.gsub!('<emph>','<i>')
    data.gsub!('</emph>','</i>')
    data.html_safe
  end

  def best_fulltext(options={})

    # alter the order of the types list below, putting the most desired links first
    types = %w(cataloglink pdf ebook-pdf ebook-epub smartlinks customlink-fulltext customlink-other)
    opts = options[:value].first

    if opts['links'].empty?
      'Not available'
    else
      label = ''
      url  = ''
      types.each do |type|
        opts['links'].each do |link|
          if link['type'] == type
            # use the new fulltext route and controller to avoid time-bombed pdf links
            if type == 'pdf' || type == 'ebook-pdf'
              url = '/catalog/' + opts['id']  + '/' + type +  '/fulltext'
            else
              url = link['url']
            end
            # replace 'URL' label for catalog links
            if type == 'cataloglink'
              label = 'Catalog Link'
            else
              label = link['label']
            end
            # sign in and redirect if guest
            if current_or_guest_user.guest
              session[:current_url] = url
              url = '/users/sign_in'
              label = label + ', login to view'
            end
            break
          end
        end
      end
      link_to(label, url, target: '_blank')
    end

  end

end