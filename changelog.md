# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - 2020-07-24
### Added
 - Added fields to Block Activity: simulated_block, http_version, http_method, risk_rtt, px_orig_cookie
 - Added fields to page_requested activity: pass_reason, risk_rtt, px_orig_cookie
 - Added px_orig_cookie field to risk_api in case of cookie_decryption_failed
 - Added support for captcha v2
 - Added support for Advanced Blocking Response
 - Added support for whitelise routes
 - Added support for bypass monitor header
 - Added support for extracting vid from _pxvid cookie
 - Added support for rate limit

### Fixed
 - Updated dependencies
 - Update sample site dockerfile
 - Fixed monitor mode
 - Fixed send_page_activities and send_block_activities configurations
 - Updated risk to v3
 - Refactored ip header extraction
 - Renamed block_uuid field to client_uuid
 - Renamed perimeterx_server_host configuration to backend_url
 - Pass the request if risk_response.status is -1

## [1.4.0] - 2018-03-18
### Fixed
 - Incorrect assigment for s2s_call_reason
 - Fixed empty token result correct s2s reason

### Added
 - Added support to captcha api v2
 - Mobile sdk support for special tokens 1/2/3


## [1.3.0] - 2017-07-27
### Added
 - Sending client_uuid on page_requested activities
 - Supporting mobile sdk
### Fixed
 - Using `request.env` instead of `env`

## [1.2.0] - 2017-06-04
### Fixed 
    - Default timeouts for post api requests
    - Fixed Dockerfile
### Changed
    - Removed httpclient and instead using typheous
### Added
    - Using concurrent-ruby for async post requests
    
## [1.1.0] - 2017-06-04
### Added 
    - Added support for sensitive routes

## [1.0.5] - 2017-05-07
### Fixed
 - Added request format into context for custom callbacks

## [1.0.4] - 2017-04-27
### Fixed
 - Constants on px_constants
 - Cookie Validation flow when cookie score was over the configured threshold
 - Using symbols instead of strings for requests body

