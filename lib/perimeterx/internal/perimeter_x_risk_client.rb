require 'perimeterx/utils/px_logger'

class PerimeterxRiskClient
  L = PxLogger.instance

  attr_accessor :px_ctx
  attr_accessor :px_config
  attr_accessor :http_client

  def initialize(px_ctx, px_config, http_client)
    @px_ctx = px_ctx
    @px_config = px_config
    @http_client = http_client;
  end

  def format_headers()
      formated_headers = []
      @px_ctx.context[:headers].each do |k,v|
        if (!@px_config['sensitive_headers'].include? k)
          formated_headers.push({k => v})
        end #end if

      end #end forech
      return formated_headers
  end #end method

end #end class
