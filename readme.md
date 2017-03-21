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
`` gem install --local perimeter_x``

<a name=basic-usage></a> Basic Usage Example
----------------------------------------
On the rails controller controller include PerimeterX sdk use it with before_action

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
    @px = PxModule.new(params)
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
Custom verification handler will replace default handle_verification method

If implemented, this method received a hash variable as input
To replace the default verification behavior, add the configuration a lambda member as in the example below

The method must return boolen value at the end

```ruby
configuration = {
  "app_id" => <APP_ID>,
  "auth_token" => <AUTH_TOKEN>,
  "custom_verification_handler" => -> (px_ctx) {
    # Method body
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
