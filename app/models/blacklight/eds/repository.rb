require 'ebsco/eds'

module Blacklight::Eds
  class Repository < Blacklight::AbstractRepository

    def find(id, params = {}, eds_params = {})
      eds = EBSCO::EDS::Session.new(eds_options(eds_params))
      dbid = id.split('__').first
      accession = id.split('__').last
      accession.gsub!(/_/, '.')
      record = eds.retrieve({dbid: dbid, an: accession})
      blacklight_config.response_model.new(record.to_solr, params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
    end

    ##
    # Execute a search against EDS
    #
    def search(search_builder = {}, eds_params = {})
      send_and_receive(blacklight_config.solr_path, search_builder, eds_params)
    end

    def send_and_receive(path, search_builder = {}, eds_params = {})
      benchmark('EDS fetch', level: :debug) do

        # results list passes a full searchbuilder, detailed record only passes params
        bl_params = search_builder.kind_of?(SearchBuilder) ? search_builder.blacklight_params : search_builder
        # todo: make highlighting configurable
        bl_params = bl_params.update({'hl'=>'on'})

        # call solr_retrieve_list if query is for a list of ids (bookmarks, email, sms, cite, etc.)
        if bl_params && bl_params['q'] && bl_params['q']['id']
          eds = EBSCO::EDS::Session.new(eds_options(eds_params))
          results = eds.solr_retrieve_list({list: bl_params['q']['id']})
          blacklight_config.response_model.new(results, bl_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
        else
          # create EDS session, perform search and convert to solr response
          eds = EBSCO::EDS::Session.new(eds_options(eds_params))
          results = eds.search(bl_params)
          results = results.to_solr
          blacklight_config.response_model.new(results, bl_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
        end

      end
    end

    # Construct EDS Session options
    def eds_options(eds_params = {})
      guest = eds_params['guest']
      session_token = eds_params['session_token']
      cache_key = guest ? 'eds_auth_token/guest' : 'eds_auth_token/user'
      auth_token = Rails.cache.fetch(cache_key, expires_in: 30.minutes, race_condition_ttl: 10) do
        s = EBSCO::EDS::Session.new
        s.auth_token
      end
      {:auth_token => auth_token, :guest => guest, :session_token => session_token}
    end

  end
end