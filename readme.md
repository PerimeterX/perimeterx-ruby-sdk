![image](http://media.marketwire.com/attachments/201604/34215_PerimeterX_logo.jpg)
#
[PerimeterX](http://www.perimeterx.com) Ruby SDK
=============================================================

Table of Contents
-----------------
-   [Usage](#usage)
  *   [Dependencies](#dependencies)
  *   [Installation](#installation)
  *   [Basic Usage Example](#basic-usage)
-   [Configuration](#configuration)

<a name="Usage"></a>
<a name="dependencies"></a> Dependencies
----------------------------------------

- Ruby version 2.3+
- Rails version 4.2
- [httparty](https://github.com/jnunemaker/httparty)

<a name="installation"></a> Installation
----------------------------------------
1. Clone the repository into your environment
2. CD into cloned repository and install gem
3. Build gem ```gem build perimeter_x.gemspec```
4. Install using bundler ```bundler install```
5. Install locally ```gem install --local perimeter_x```
6. On Gemfile, add it as a local dependency ```gem 'perimeter_x', :path => '<ACTUAL_PATH>'``` 

<a name=basic-usage></a> Basic Usage Example
----------------------------------------
On the Rails controller include the PerimeterX SDK via the before_action which will call your defined middleware function. This function is a wrapper for the px_verify method which takes a request and processes it. The verify method can return true if verified, or false if not verified.

The default condition is to always return true for monitoring mode.

```
class HomeController < ApplicationController
  include PerimeterX
  attr_accessor :px
  ...
  ...
  before_action :px_middleware
  ...
  ...
  initialize()
    configuration = {
      "app_id" => <APP_ID>
      "auth_token" => <AUTH_TOKEN>
    }
    @px = PxModule.instance(params)
  end
  ...
  ...
  def px_middleware
    px.px_verify(request.env)
  end
```

<a name="configuration"></a> Configuration
----------------------------------------

** Custom Verification Handler **
A custom verification handler replaces the default handle_verification method and allows you to take a custom action based on the risk score returned by PerimeterX.

When implemented, this method receives  a hash variable as input which represents data from the PerimeterX context of the request (px_ctx).

- `px_ctx[:score] ` contains the risk score 
- `px_ctx[:uuid] ` contains the request UUID 

To replace the default verification behavior, add the configuration a lambda member as shown in the example below.

The method must return boolen value.



```ruby
configuration = {
  "app_id" => <APP_ID>,
  "auth_token" => <AUTH_TOKEN>,
  "custom_verification_handler" => -> (px_ctx) {
    if px_ctx[:score] >= 60
        # take your action and retun a message or JSON with a status code of 403 and option UUID of the request. Can return false and include action in the px_middleware method.  
    end
    return true
  }
}
```

** Custom User IP **

> Note: IP extraction, according to your network setup, is very important. It is common to have a load balancer/proxy on top of your applications, in which case the PerimeterX module will send the system's internal IP as the user's. In order to properly perform processing and detection on server-to-server calls, PerimeterX module needs the real user's IP.

By default the clients IP is taken from the ``REMOTE_ADDR`` header, in case the user decides to use different header or custom function that extract the header the following key should be added to the configuration

*** Custom header ***
```ruby
configuration = {
  "app_id" => <APP_ID>,
  "auth_token" => <AUTH_TOKEN>,
  "custom_user_ip" => <HTTP_HEADER_NAME>,
```

*** Custom Function ***
> Note: the function receive as a first parameter the controller request and must return the ip at the end as string

```ruby
configuration = {
  "app_id" => <APP_ID>,
  "auth_token" => <AUTH_TOKEN>,
  "custom_user_ip_method" => -> (req) {
    # Method body
    return "1.2.3.4"
  }
}
```
