require 'perimeterx/utils/px_logger'

class PxHttpClient
  L = PxLogger.instance
  attr_accessor :px_config
  attr_accessor :BASE_URL

  def initialize(px_config)
    L.info("PxHttpClient[initialize]: HTTP client is being initilized with base_uri: #{px_config['perimeterx_server_host']}")
    @px_config = px_config
  end

  def post(path, body, headers, connection_timeout = 0, timeoute = 0)
    begin
      s = Time.now
      L.info("PxHttpClient[post]: posting to #{path} headers {#{headers.to_json()}} body: {#{body.to_json()}} ")
      response = HTTParty.post("#{@px_config['perimeterx_server_host']}#{path}",
                               :headers => headers,
                               :body => body.to_json(),
                               :timeout => @px_config['api_timeout']
      )
    rescue Net::OpenTimeout, Net::ReadTimeout => error
      L.warn("PerimeterxS2SValidator[verify]: request timedout")
      return false


    e = Time.now
    L.info("PxHttpClient[post]: runtime: #{e-s}")
    return response
    end
  end

end
