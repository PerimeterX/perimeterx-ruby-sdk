require "perimeterx/utils/px_logger"
require "httpclient"

module PxModule
  class PxHttpClient
    attr_accessor :px_config
    attr_accessor :BASE_URL
    attr_accessor :http_client

    def initialize(px_config)
      @px_config = px_config
      @http_client = HTTPClient.new(:base_url => px_config[:perimeterx_server_host])
      @logger = px_config[:logger]
      @logger.debug("PxHttpClient[initialize]: HTTP client is being initilized with base_uri: #{px_config[:perimeterx_server_host]}")
    end

    def post(path, body, headers, api_timeout = 0, timeoute = 0)
      s = Time.now
      begin
        @logger.debug("PxHttpClient[post]: posting to #{path} headers {#{headers.to_json()}} body: {#{body.to_json()}} ")
        response = @http_client.post(path,
                    :header => headers,
                    :body => body.to_json(),
                    :timeout => api_timeout
                  )
      rescue Net::OpenTimeout, Net::ReadTimeout => error
        @logger.warn("PerimeterxS2SValidator[verify]: request timedout")
        return false
      end
      e = Time.now
      @logger.debug("PxHttpClient[post]: runtime: #{e-s}")
      return response
    end

    def async_post(path, body, headers, api_timeout = 0, timeoute = 0)
      @logger.debug("PxHttpClient[async_post]: posting to #{path} headers {#{headers.to_json()}} body: {#{body.to_json()}} ")
      s = Time.now
      begin
        @logger.debug("PxHttpClient[post]: posting to #{path} headers {#{headers.to_json()}} body: {#{body.to_json()}} ")
        response = @http_client.post_async(path,
                    :header => headers,
                    :body => body.to_json(),
                    :timeout => api_timeout
                  )
      rescue Net::OpenTimeout, Net::ReadTimeout => error
        @logger.warn("PerimeterxS2SValidator[verify]: request timedout")
        return false
      end
      e = Time.now
      @logger.debug("PxHttpClient[post]: runtime: #{e-s}")
      return response
    end

  end
end
