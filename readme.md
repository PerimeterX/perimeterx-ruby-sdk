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

- Ruby version 2.4+
- Rails version 5.1
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
