require 'ebsco/eds'

module Blacklight::Eds
  class Repository < Blacklight::AbstractRepository

    def find(id, params = {}, eds_params = {})
      # doc_params = params.reverse_merge(blacklight_config.default_document_solr_params)
      #                  .reverse_merge(qt: blacklight_config.document_solr_request_handler)
      #                  .merge(blacklight_config.document_unique_id_param => id)
      # puts 'DOC PARAMS: ' + doc_params.inspect
      guest = eds_params['guest']
      eds = EBSCO::EDS::Session.new({:auth_token => eds_auth_token(guest)}.update(eds_params))
      dbid = id.split('__').first
      accession = id.split('__').last
      accession.gsub!(/_/, '.')
      record = eds.retrieve({dbid: dbid, an: accession})
      eds_response = record.to_solr

      solr_response = blacklight_config.response_model.new(eds_response, params,
                                                           document_model: blacklight_config.document_model,
                                                           blacklight_config: blacklight_config)
      puts 'SOLR RESPONSE (find): ' + solr_response.inspect
      solr_response
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
        if search_builder.kind_of?(SearchBuilder)
          bl_params = search_builder.blacklight_params
        else
          bl_params = search_builder
        end

        # determine guest status
        guest = eds_params['guest']

        eds = EBSCO::EDS::Session.new({:auth_token => eds_auth_token(guest)}.update(eds_params))

        eds_results = eds.search(bl_params.update({'hl'=>'on'}))

        if bl_params.has_key?('page')
          eds_results = eds.get_page(bl_params['page'].to_i)
        end

        solr_response = blacklight_config.response_model.new(eds_results.to_solr, bl_params,
                                                             document_model: blacklight_config.document_model,
                                                             blacklight_config: blacklight_config)

        solr_response
      end
    end

    # Returns EDS auth_token. It's stored in Rails Low Level Cache, and expires in every 30 minutes
    def eds_auth_token( guest = true)
      cache_key = guest ? 'eds_auth_token/guest' : 'eds_auth_token/user'
      auth_token = Rails.cache.fetch(cache_key, expires_in: 30.minutes, race_condition_ttl: 10) do
        s = EBSCO::EDS::Session.new
        s.auth_token
      end
      #Blacklight.logger.debug 'Cache Key: ' << cache_key
      #Blacklight.logger.debug 'EDS Auth Token: ' << auth_token
      auth_token
    end

  end
end