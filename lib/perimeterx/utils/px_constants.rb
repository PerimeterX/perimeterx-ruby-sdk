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
  API_V3_RISK = '/api/v3/risk'

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
  CHALLENGE_TEMPLATE = 'block_template'
  TEMPLATE_EXT = '.mustache'


  # Template Props
  PROP_REF_ID = :refId
  PROP_APP_ID = :appId
  PROP_VID = :vid
  PROP_UUID = :uuid
  PROP_LOGO_VISIBILITY = :logoVisibility
  PROP_CUSTOM_LOGO = :customLogo
  PROP_CSS_REF = :cssRef
  PROP_JS_REF = :jsRef
  PROP_BLOCK_SCRIPT = :blockScript
  PROP_JS_CLIENT_SRC = :jsClientSrc
  PROP_HOST_URL = :hostUrl
  PROP_FIRST_PARTY_ENABLED = :firstPartyEnabled

  # Hosts
  CLIENT_HOST = 'client.px-cloud.net'
  CAPTCHA_HOST = 'captcha.px-cloud.net'

  VISIBLE = 'visible'
  HIDDEN = 'hidden'

  # Mobile SDK
  TOKEN_HEADER = 'X-PX-AUTHORIZATION'
  MOBILE_SDK_CONNECTION_ERROR = 'mobile_sdk_connection_error'
  MOBILE_SDK_PINNING_ERROR = 'mobile_sdk_pinning_error'
end
