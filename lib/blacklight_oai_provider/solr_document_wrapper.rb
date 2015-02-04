module BlacklightOaiProvider
  class SolrDocumentWrapper < ::OAI::Provider::Model
    attr_reader :model, :timestamp_field
    attr_accessor :options
    def initialize(controller, options = {})
      @controller = controller

      defaults = { :timestamp => 'timestamp', :limit => 15} 
      @options = defaults.merge options

      @timestamp_field = @options[:timestamp]
      @limit = @options[:limit]
    end

    def sets
    end
    
    def earliest
      Time.parse @controller.get_search_results(@controller.params, {:qt => 'oai', :fq => '-active_fedora_model_ssi:Page -has_model_ssim:info\:fedora\/afmodel\:collection', :fl => @timestamp_field, :sort => @timestamp_field +' asc', :rows => 1}).last.first.get(@timestamp_field)
    end

    def latest
      Time.parse @controller.get_search_results(@controller.params, {:qt => 'oai', :fq => '-active_fedora_model_ssi:Page -has_model_ssim:info\:fedora\/afmodel\:collection', :fl => @timestamp_field, :sort => @timestamp_field +' desc', :rows => 1}).last.first.get(@timestamp_field)
    end

    def find(selector, options={})
      return next_set(options[:resumption_token]) if options[:resumption_token]

      if :all == selector
        response, records = @controller.get_search_results(@controller.params, {:qt => 'oai', :fq => '-active_fedora_model_ssi:Page -has_model_ssim:info\:fedora\/afmodel\:collection', :sort => @timestamp_field + ' asc', :rows => @limit})

        if @limit && response.total >= @limit
          return select_partial(OAI::Provider::ResumptionToken.new(options.merge({:last => 0})))
        end
        if @limit && response.total < @limit
          return select__incomplete_partial(OAI::Provider::ResumptionToken.new(options.merge({:last => 0})))
        end
      else                                                    
        response, records = @controller.get_solr_response_for_doc_id selector.split('/', 2).last
      end
      records
    end

    def select_partial token
      records = @controller.get_search_results(@controller.params, {:qt => 'oai', :fq => '-active_fedora_model_ssi:Page -has_model_ssim:info\:fedora\/afmodel\:collection', :sort => @timestamp_field + ' asc', :rows => @limit, :start => token.last}).last

      raise ::OAI::ResumptionTokenException.new unless records

      OAI::Provider::PartialResult.new(records, token.next(token.last+@limit))
    end
    def select_incomplete_partial token
      records = @controller.get_search_results(@controller.params, {:qt => 'oai', :fq => '-active_fedora_model_ssi:Page -has_model_ssim:info\:fedora\/afmodel\:collection', :sort => @timestamp_field + ' asc', :rows => @limit, :start => token.last}).last

      raise ::OAI::ResumptionTokenException.new unless records

      OAI::Provider::PartialResult.new(records)
    end

    def next_set(token_string)
      raise ::OAI::ResumptionTokenException.new unless @limit

      token = OAI::Provider::ResumptionToken.parse(token_string)
      select_partial(token)
    end
  end
end

