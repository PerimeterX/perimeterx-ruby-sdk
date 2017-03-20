require 'perimeterx/utils/px_logger'

class PxHttpClient
  L = PxLogger.instance

  attr_accessor :client
  attr_accessor :px_config

  def initialize(px_config)
    @px_config = px_config
    http_client_config = {
      base_uri => px_config[:perimeterx_server_host]
    }
    @client = HTTPClient.new(http_client_config)
  end

  def send(url, method, json, headers, timeout = 0, connect_timeout = 0)



    raw_response = @client(method, url,
      {
        'json' => $json,
        'headers' => $headers,
        'timeout' => $timeout,
        'connect_timeout' => $connect_timeout
      }
    );

  end

end
