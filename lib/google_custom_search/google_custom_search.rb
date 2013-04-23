require 'net/http'
require 'addressable/uri'

##
# Add search functionality (via Google Custom Search). Protocol reference at:
# http://www.google.com/coop/docs/cse/resultsxml.html
#
module GoogleCustomSearch
  extend self

  ##
  # Search the site.
  #
  def search(query, options = {})
    # Get and parse results.
    uri = build_uri(query, options)
    begin
      return nil unless xml = fetch_xml(uri)
    rescue Timeout::Error => e
      raise GoogleCustomSearch::TimeoutError, e.message
    end

    return ResultSet.new(xml)
  end

  ##
  # Expose configuration object
  #
  def configuration
    @configuration ||= GoogleCustomSearch::Configuration.new
  end

  ##
  # Configuration helper method
  #
  def configure
    yield(configuration) if block_given?
  end

  private # -------------------------------------------------------------------

  ##
  # Build search request URI.
  #
  def build_uri(query, options = {})
    options = { :offset => 0, :per_page => 10 }.merge(options.delete_if { |k,v| v.nil? })

    if options[:page]
      options[:offset] = calculated_offset(options)
    end

    params = {
      :q      => query,
      :start  => options[:offset],
      :num    => options[:per_page],
      :client => "google-csbe",
      :output => "xml_no_dtd",
      :cx     => GoogleCustomSearch.configuration.cx
    }

    if GoogleCustomSearch.configuration.default_params
      params.merge!(GoogleCustomSearch.configuration.default_params)
    end

    if GoogleCustomSearch.configuration.secure
      uri = Addressable::URI.parse("https://www.google.com/cse")
      uri.port = 443
    else
      uri = Addressable::URI.parse("http://www.google.com/cse")
    end

    uri.query_values = params
    return uri
  end

  ##
  # Query Google, and make sure it responds.
  #
  def fetch_xml(uri)
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.read_timeout = GoogleCustomSearch.configuration.timeout

    request = Net::HTTP::Get.new(uri.request_uri)
    request.initialize_http_header({ 'User-Agent' => user_agent })

    response = http.request(request)

    raise GoogleCustomSearch::InvalidRequest if response.code.match(/[34]\d{2}/)
    raise GoogleCustomSearch::ServerError if response.code.match(/5\d{2}/)

    response.body
  end

  def user_agent
    "GoogleCustomSearch/#{GoogleCustomSearch::VERSION} - https://github.com/cosm/google_custom_search (Ruby/#{RUBY_VERSION})"
  end

  def calculated_offset(options)
    page = options[:page].to_i < 1 ? 1 : options[:page].to_i

    return (page - 1) * options[:per_page].to_i
  end
end
