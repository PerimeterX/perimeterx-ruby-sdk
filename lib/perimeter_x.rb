require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/clients/perimeter_x_activity_client'
require 'perimeterx/internal/validators/perimeter_x_s2s_validator'
require 'perimeterx/internal/validators/perimeter_x_cookie_validator'
require 'perimeterx/internal/validators/perimeter_x_captcha_validator'

module PxModule
  class PerimeterX
    L = PxLogger.instance

    @@singleton__instance__ = nil
    @@singleton__mutex__ = Mutex.new

    attr_reader :px_config
    attr_accessor :px_http_client
    attr_accessor :px_activity_client

    def self.instance(params)
      return @@singleton__instance__ if @@singleton__instance__
      @@singleton__mutex__.synchronize {
        return @@singleton__instance__ if @@singleton__instance__
        @@singleton__instance__ = new(params)
      }
      @@singleton__instance__
    end


    private def initialize(params)
      L.debug("PerimeterX[initialize]")
      @px_config = Configuration.new(params).configuration
      @px_http_client = PxHttpClient.new(@px_config)

      @px_activity_client = PerimeterxActivitiesClient.new(@px_config, @px_http_client)

      @px_cookie_validator = PerimeterxCookieValidator.new(@px_config)
      @px_s2s_validator = PerimeterxS2SValidator.new(@px_config, @px_http_client)
      @px_captcha_validator = PerimeterxCaptchaValidator.new(@px_config, @px_http_client)
    end

    def px_verify(env)
      begin
        L.debug("PerimeterX[pxVerify]")
        req = ActionDispatch::Request.new(env)

        if (!@px_config[:module_enabled])
          L.warn("Module is disabled")
          return true
        end

        px_ctx = PerimeterXContext.new(@px_config, req)

        # Captcha phase
        captcha_verified, px_ctx = @px_captcha_validator.verify(px_ctx)
        if (captcha_verified)
          return handle_verification(px_ctx)
        end

        # Cookie phase
        cookie_verified, px_ctx = @px_cookie_validator.verify(px_ctx)
        if (!cookie_verified)
          @px_s2s_validator.verify(px_ctx)
        end

        if (@px_config.key?(:custom_verification_handler))
          return @px_config[:custom_verification_handler].call(px_ctx.context)
        else
          return handle_verification(px_ctx)
        end
      rescue Exception => e
        L.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
        e.backtrace.drop(1).map { |s| L.error("\t#{s}") }
        return true
      end
    end

    # private methods
    private def handle_verification(px_ctx)
      L.debug("PerimeterX[handle_verification]")
      L.debug("PerimeterX[handle_verification]: processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")

      score = px_ctx.context[:score]
      # Case PASS request
      if (score < @px_config[:blocking_score])
        L.debug("PerimeterX[handle_verification]: score:#{score} < blocking score, passing request")
        @px_activity_client.send_page_requested_activity(px_ctx)
        return true
      end

      # Case blocking activity
      @px_activity_client.send_block_activity(px_ctx)

      # custom_block_handler - custom block handler defined by the user
      if(@px_config.key?(:custom_block_handler))
        L.debug("PerimeterX[handle_verification]: custom block handler triggered")
        @px_config[custom_block_handler].call(px_ctx)
      end

      # In case were in monitor mode, end here
      if(@px_config[:module_mode] == PxModule::ACTIVE_MODE)
        L.debug("PerimeterX[handle_verification]: monitor mode is on, passing request")
        return true
      end

      L.debug("PerimeterX[handle_verification]: sending block page")
      #TODO: Render HTML from here

      full_url = px_ctx.context[:full_url]
      ref_str = px_ctx.context[:uuid]
      html = "<html lang='en'>\n<head>\n    <link type='text/css' rel='stylesheet' media='screen, print'\n          href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800'>\n    <meta charset='UTF-8'>\n    <title>Access to This Page Has Been Blocked</title>\n    <style> p {\n        width: 60%;\n        margin: 0 auto;\n        font-size: 35px;\n    }\n\n    body {\n        background-color: #a2a2a2;\n        font-family: 'Open Sans';\n        margin: 5%;\n    }\n\n    img {\n        widht: 180px;\n    }\n\n    a {\n        color: #2020B1;\n        text-decoration: blink;\n    }\n\n    a:hover {\n        color: #2b60c6;\n    } </style>\n    <style type='text/css'></style>\n</head>\n<body cz-shortcut-listen='true'>\n<div><img\n        src='https://s.perimeterx.net/logo.png'>\n</div>\n<span style='color: white; font-size: 34px;'>Access to This Page Has Been Blocked</span>\n<div style='font-size: 24px;color: #000042;'><br> Access to #{full_url} is blocked according to the site security policy.\n    <br> Your browsing behaviour fingerprinting made us think you may be a bot. <br> <br> This may happen as a result of\n    the following:\n    <ul>\n        <li>JavaScript is disabled or not running properly.</li>\n        <li>Your browsing behaviour fingerprinting are not likely to be a regular user.</li>\n    </ul>\n    To read more about the bot defender solution: <a href='https://www.perimeterx.com/bot-defender'>https://www.perimeterx.com/bot-defender</a>\n    <br> If you think the blocking was done by mistake, contact the site administrator. <br> <br>\n\n    <span style='font-size: 20px;'>Block Reference: <span\n            style='color: #525151;'># #{ref_str}</span></span></div>\n</body>\n</html>".html_safe
      if @px_config[:captcha_enabled]
        html =" <html lang='en'>\n<head>\n    <link type='text/css' rel='stylesheet' media='screen, print'\n          href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800'>\n    <meta charset='UTF-8'>\n    <title>Access to This Page Has Been Blocked</title>\n    <style> p {\n        width: 60%;\n        margin: 0 auto;\n        font-size: 35px;\n    }\n\n    body {\n        background-color: #a2a2a2;\n        font-family: 'Open Sans';\n        margin: 5%;\n    }\n\n    img {\n        widht: 180px;\n    }\n\n    a {\n        color: #2020B1;\n        text-decoration: blink;\n    }\n\n    a:hover {\n        color: #2b60c6;\n    } </style>\n    <style type='text/css'></style>\n    <script src=\'https://www.google.com/recaptcha/api.js\'></script>\n    <script>\n        window.px_vid = '#{px_ctx.context[:vid]}' ; \n        function handleCaptcha(response) {\n            var name = \'_pxCaptcha\';\n            var expiryUtc = new Date( Date.now() + 1000 * 10 ).toUTCString();\n            var cookieParts = [name, \'=\', response + \':\' + window.px_vid + \':#{px_ctx.context[:uuid]}\', \'; expires=\', expiryUtc, \'; path=/\'];\n            document.cookie = cookieParts.join(\'\');\n            location.reload();\n        }\n    </script>\n</head>\n<body cz-shortcut-listen='true'>\n<div><img\n        src='https://s.perimeterx.net/logo.png'>\n</div>\n<span style='color: white; font-size: 34px;'>Access to This Page Has Been Blocked</span>\n<div style='font-size: 24px;color: #000042;'><br> Access to #{ full_url } is blocked according to the site security policy.\n    <br> Your browsing behaviour fingerprinting made us think you may be a bot. <br> <br> This may happen as a result of\n    the following:\n    <ul>\n        <li>JavaScript is disabled or not running properly.</li>\n        <li>Your browsing behaviour fingerprinting are not likely to be a regular user.</li>\n    </ul>\n    To read more about the bot defender solution: <a href='https://www.perimeterx.com/bot-defender'>https://www.perimeterx.com/bot-defender</a>\n    <br> If you think the blocking was done by mistake, contact the site administrator. <br> <br><div class='g-recaptcha' data-sitekey='6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b' data-callback='handleCaptcha' data-theme='dark'></div>\n\n    <span style='font-size: 20px;'>Block Reference: <span\n            style='color: #525151;'># #{ref_str}</span></span></div>\n</body>\n</html>".html_safe
      end


      return false, html

    end

    private_class_method :new
  end

end
