# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

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

