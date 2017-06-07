# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

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
