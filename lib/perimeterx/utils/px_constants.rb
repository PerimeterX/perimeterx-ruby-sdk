require 'perimeterx/version'

module PxModule
  # Misc
  MONITOR_MODE = 1
  ACTIVE_MODE = 2
  RISK_MODE_ACTIVE = 'active_blocking'
  RISK_MODE_MONITOR = 'monitor'
  SDK_NAME = "RUBY SDK v#{PxModule::VERSION}"

  # Routes
  API_V1_S2S = '/api/v1/collector/s2s'
  API_V1_CAPTCHA = '/api/v1/risk/captcha'
  API_V2_RISK = '/api/v2/risk'

  # Activity Types
  BLOCK_ACTIVITY = 'block'
  PAGE_REQUESTED_ACTIVITY = 'page_requested'

  # PxContext
  NO_COOKIE = 'no_cookie'
  INVALID_COOKIE = 'invalid_cookie'
  EXPIRED_COOKIE = 'cookie_expired'
  COOKIE_HIGH_SCORE = 'cookie_high_score'
  COOKIE_VALIDATION_FAILED = 'cookie_validation_failed'
  COOKIE_DECRYPTION_FAILED = 'cookie_decryption_failed'
  SENSITIVE_ROUTE = 'sensitive_route'

  # Templates
  BLOCK_TEMPLATE = 'block.mustache'
  CAPTCHA_TEMPLATE = 'captcha.mustache'

  # Template Props
  PROP_REF_ID = :refId
  PROP_APP_ID = :appId
  PROP_VID = :vid
  PROP_UUID = :uuid
  PROP_LOGO_VISIBILITY = :logoVisibility
  PROP_CUSTOM_LOGO = :customLogo
  PROP_CSS_REF = :cssRef
  PROP_JS_REF = :jsRef

  VISIBLE = 'visible'
  HIDDEN = 'hidden'

  # Remote Configurations
  REMOTE_CONFIG_SERVER = 'https://px-conf.perimeterx.net'
  REMOTE_CONFIG_PATH = '/module'
end
