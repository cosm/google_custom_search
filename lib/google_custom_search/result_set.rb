module GoogleCustomSearch
  class ResultSet

    attr_accessor :total_entries, :results, :per_page, :start_index, :end_index,
      :suggestion

    def initialize(xml)
      parse(xml)
    end

    def current_page
      (@start_index.to_f / @per_page).ceil
    end

    def offset
      @start_index - 1
    end

    def total_pages
      (@total_entries.to_f / @per_page).ceil
    end

    private

    ##
    # Try to parse all useful information out of the returned Google query
    # response document
    def parse(xml)
      begin
        data = MultiXml.parse(xml)['GSP']
      rescue MultiXml::ParseError => e
        raise GoogleCustomSearch::InvalidXML, e.message
      end

      if data['RES']
        @total_entries = data['RES']['M'].to_i
        @start_index = data['RES']['SN'].to_i
        @end_index = data['RES']['EN'].to_i

        @results = parse_results(data['RES']['R'])
      else
        @total_entries = 0
        @results = []
      end

      @per_page = data['PARAM'].detect { |param| param["name"] == "num" }["value"].to_i

      if data["Spelling"]
        @suggestion = data["Spelling"]["Suggestion"]["q"]
      end
    end

    ##
    # Transform an array of Google search results (XML parsed by MultiXml) into
    # a more useful format.
    #
    def parse_results(results)
      out = []
      results = [results] if results.is_a?(Hash) # no array if only one result
      results.each do |r|
        out << Result.new(r)
      end
      out
    end
  end
end
