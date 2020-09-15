require 'perimeterx/utils/px_logger'
require 'typhoeus'
require 'concurrent'
require 'net/http'

module PxModule
  class PxHttpClient
    include Concurrent::Async

    attr_accessor :px_config
    attr_accessor :px_client

    def initialize(px_config)
      @px_config = px_config
      @logger = px_config[:logger]
      @logger.debug("PxHttpClient[initialize]: HTTP client is being initilized with base_uri: #{px_config[:backend_url]}")
    end

    # Runs a POST command to Perimeter X servers
    # Params:
    # +path+:: string containing uri
    # +body+:: hash object, containing the request body, must be converted to json format
    # +headers+:: hash object, hold headers
    # +api_timeout+:: int, sets the timeout for a request
    # +connection_timeout+:: int, sets the timeout for opening a connection

    def post(path, body, headers, api_timeout = 1, connection_timeout = 1)
      s = Time.now
      begin
        @logger.debug("PxHttpClient[post]: posting to #{path} headers {#{headers.to_json()}} body: {#{body.to_json()}} ")
        response = Typhoeus.post(
            "#{px_config[:backend_url]}#{path}",
            headers: headers,
            body: body.to_json,
            timeout: api_timeout,
            connecttimeout: connection_timeout
        )
        if response.timed_out?
          @logger.warn('PerimeterxS2SValidator[verify]: request timed out')
          return false
        end
      ensure
        e = Time.now
        @logger.debug("PxHttpClient[post]: runtime: #{(e-s) * 1000.0}")
      end
      return response
    end


    def post_xhr(url, body, headers)
      s = Time.now
      begin
        @logger.debug("PxHttpClient[post]: sending xhr post request to #{url} with headers {#{headers.to_json()}}")
        
        #set url
        uri = URI(url)
        req = Net::HTTP::Post.new(uri)
        
        # set body
        req.body=body
        
        # set headers
        headers.each do |key, value|
          req[key] = value
        end
        
        # send request   
        response = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }

      ensure
        e = Time.now
        @logger.debug("PxHttpClient[get]: runtime: #{(e-s) * 1000.0}")
      end
      return response
    end


    def get(url, headers)
      s = Time.now
      begin
        @logger.debug("PxHttpClient[get]: sending get request to #{url} with headers {#{headers.to_json()}}")
        
        #set url
        uri = URI(url)
        req = Net::HTTP::Get.new(uri)
        
        # set headers
        headers.each do |key, value|
          req[key] = value
        end
        
        # send request   
        response = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }
        
      ensure
        e = Time.now
        @logger.debug("PxHttpClient[get]: runtime: #{(e-s) * 1000.0}")
      end
      return response
    end
  end
end
