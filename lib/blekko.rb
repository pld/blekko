require 'rubygems'

require 'cgi'
require 'json'
require 'open-uri'


BlekkoResult = Struct.new :title, :abstract, :url, :display_url, :short_host,
    :short_host_url, :rss, :main_slashtag_boosted, :date


class Blekko 
  # API for Blekko search engine
  # 
  # Example:
  #   >> Blekko.new('[Referer]', ['Num results']).search('nano fibers')
  #   => [ #<ClioResult:...>, ... ]
  #
  # Arguments:
  #   referer: (String)
  #   num_results: (Integer+)

  API_PROTOCOL_HTTPS = 'https://'
  API_PROTOCOL_HTTP = 'http://'
  API_PATH = 'www.blekko.com/ws/?q='
  CHUNK_SIZE = 10
  MAX_TTL = 2
  MIN_SECS_BTWN_REQS = 1

  attr_accessor :referer, :num_results, :api_key, :last_request

  def initialize(api_key='', referer='', num_results=100, secure=true)
    @api_protocol = secure ? API_PROTOCOL_HTTPS : API_PROTOCOL_HTTP
    @api_key = api_key
    @referer = referer
    @num_results = num_results
    @last_request = nil
  end

  def search(query, page=1)
    # API Parameters
    # auth=api key
    # q=query
    # p=page
    # ps=num results

    params = "#{CGI.escape(query)}+/json+/ps=#{@num_results}&auth=#{@api_key}"

    url = "#{@api_protocol}#{API_PATH}#{params}&p=#{page}"

    # enforce rate limit
    sleep_for_rate_limit

    response = open(url, { 'Referer' => @referer })
    unless response.class.superclass == Net::HTTPServerError
      doc = JSON.load(response)
      @json = doc

      # if total_num is defined, then RESULTS is
      return [] unless doc['total_num']
      doc['RESULT'].map do |result|
        BlekkoResult.new(
          result['url_title'],
          result['snippet'],
          result['url'],
          result['display_url'],
          result['short_host'],
          result['short_host_url'],
          result['rss'],
          result['main_slashtag_boosted'],
          Time.now
        )
      end
    end
  end

  private
  def sleep_for_rate_limit
    # If we have a last request, the minimum time between requests has not
    # passed, and the time to sleep is positive (in case the check got blocked),
    # then sleep for the needed time.
    # In any case, reset the last request time to now.
    if @last_request and\
        (Time.now) - @last_request < MIN_SECS_BTWN_REQS and\
        (time_to_sleep = MIN_SECS_BTWN_REQS - (Time.now - @last_request)) > 0
      sleep time_to_sleep
    end
    @last_request = Time.now
  end
end
