[![Build Status](https://travis-ci.org/PerimeterX/perimeterx-ruby-sdk.svg?branch=master)](https://travis-ci.org/PerimeterX/perimeterx-ruby-sdk)

![image](https://storage.googleapis.com/perimeterx-logos/primary_logo_red_cropped.png)
#
[PerimeterX](http://www.perimeterx.com) Ruby SDK
=============================================================

> Latest stable version: [v2.1.0](https://rubygems.org/gems/perimeter_x)

Table of Contents
-----------------
  **[Usage](#usage)**
  *   [Dependencies](#dependencies)
  *   [Installation](#installation)
  *   [Basic Usage Example](#basic-usage)
  
  **[Configuration](#configuration)**
  *   [Configuring Required Parameters](#requireied-params)
  *   [Blocking Score](#blocking-score)
  *   [Custom Verification Action](#custom-verification-action)
  *   [Custom Block Page](#custom-block-page)
  *   [Extracting Real IP Address](#real-ip)
  *   [Custom URI](#custom-uri)
  *   [Filter Sensitive Headers](#sensitive-headers)
  *   [API Timeouts](#api-timeout)
  *   [Send Page Activities](#send-page-activities)
  *   [Additional Page Activity Handler](#additional-page-activity-handler)
  *   [Monitor Only](#logging)
  *   [Debug Mode](#debug-mode)
  *   [Whitelist Routes](#whitelist-routes)
  *   [Update Configuration on Runtime](#update-config)
  *   [First Party](#first-party)
  
  **[Contributing](#contributing)**

<a name="Usage"></a>
<a name="dependencies"></a> Dependencies
----------------------------------------

- Ruby version 2.3+
- Rails version 4.2
- [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby)
- [typhoeus](https://github.com/typhoeus/typhoeus)
- [mustache](https://rubygems.org/gems/mustache)

<a name="installation"></a> Installation
----------------------------------------
Install it through command line ```gem install perimeter_x```


<a name=basic-usage></a> Basic Usage Example
----------------------------------------

### Configuration & Initialization
Create a configuration file at `<rails_app>/config/initializers/perimeterx.rb` and initialize PerimeterX instance on the rails application startup
```ruby
params = {
  :app_id => "APP_ID",
  :cookie_key => "COOKIE_KEY",
  :auth_token => "AUTH_TOKEN"
}

PxModule.configure(params)
```

On the Rails controller include the PerimeterX SDK via the before_action and call PerimterX middleware function.

```ruby
class HomeController < ApplicationController
  include PxModule

  before_action :px_verify_request
  ...
  ...
end
```

<a name="configuration"></a> Configuration options
----------------------------------------
<a name="requireied-params"></a>**Configuring Required Parameters**
Configuration options are set on the ``params`` variable on the initializer file.

- ``app_id``
- ``cookie_key``
- ``auth_token``

All parameters are obtainable via the PerimeterX Portal. (Applications and Policies pages)

<a name="blocking-score"></a>**Changing the Minimum Score for Blocking**

>Note:  Default blocking value: 100

```ruby
params = {
  ...
  :blocking_score => 100
  ...
}
```

<a name="custom-verification-action"></a>**Custom Verification Handler**

> Note: This handler replaces the now deprecated `custom_block_handler`.

A custom verification handler is being executed inside `px_verify_request` instead of the the default behavior and allows a user to use a custom action based on the risk score returned by PerimeterX.

When implemented, this method receives a hash variable as input which represents data from the PerimeterX context of the request (px_ctx).

- `px_ctx.context[:score]` - contains the risk score
- `px_ctx.context[:uuid]` - contains the request UUID
- `px_ctx.context[:verified]` - contains indication whether the request passed verification or was blocked (inspect `px_ctx.context[:block_reason]` for block reason) 

> Note: to determine whether to return a captcha/block page (HTML) or block JSON payload a reference key on the context will be available:  ```px_ctx.context[:format]```

To replace the default verification behavior, add the configuration a lambda member as shown in the example below.

```ruby
params = {
  :app_id => <APP_ID>,
  :auth_token => <AUTH_TOKEN>,
  :custom_verification_handler => -> (px_ctx) {
    if px_ctx.context[:score] >= 60
      # take your action and render an html page or JSON with applicable status code.    
      render json: { :score => px_ctx.context[:score] }
    end
  }
}
```

> Note: Unlike previous versions, the method no longer needs to return a boolean value. 

**Example**
#### Serving a Custom HTML Page ####
```ruby

params = {
  :app_id => <APP_ID>,
  :auth_token => <AUTH_TOKEN>,
  ...
  :custom_verification_handler => -> (px_ctx) {
    block_score = px_ctx.context[:score];
    client_uuid = px_ctx.context[:uuid];
    full_url = px_ctx.context[:full_url];

    html = "<html>
            <body>
            <div>Access to #{full_url} has been blocked.</div>    
            <div>Block reference - #{client_uuid} </div>
            <div>Block score - #{block_score} </div>
            </body>
            </html>".html_safe
    response.headers["Content-Type"] = "text/html"
    response.status = 403
    render :html => html
  }
}
```

<a name="real-ip"></a>**Custom User IP**

> Note: IP extraction, according to your network setup, is very important. It is common to have a load balancer/proxy on top of your applications, in which case the PerimeterX module will send the system's internal IP as the user's. In order to properly perform processing and detection on server-to-server calls, PerimeterX module needs the real user's IP.

By default the clients IP is taken from the ``REMOTE_ADDR`` header, in case the user decides to use different header or custom function that extract the header the following key should be added to the configuration

***Custom header***
```ruby
configuration = {
  "app_id" => <APP_ID>,
  "auth_token" => <AUTH_TOKEN>,
  "custom_user_ip" => <HTTP_HEADER_NAME>,
```

***Custom Function***
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
<a name="custom-block-page"></a>**Customizing Default Block Pages**

Adding a custom logo to the blocking page is by providing the `params` a key `custom_logo` , the logo will be displayed at the top div of the the block page The logo's `max-heigh` property would be `150px` and width would be set to `auto`

The key custom_logo expects a valid URL address such as https://s.perimeterx.net/logo.png

```ruby
params = [
    :app_id => 'APP_ID',
    :cookie_key => 'COOKIE_SECRET',
    :auth_token => 'AUTH_TOKEN',
    :custom_logo => 'LOGO_URL'
];
```

**Custom JS/CSS**
The block page can be modified with a custom CSS by adding to the `params` the key `css_ref` and providing a valid URL to the css In addition there is also the option to add a custom JS file by adding `js_ref` key to the pxConfig and providing the JS file that will be loaded with the block page, this key also expects a valid URL

```ruby
params = [
    :app_id => 'APP_ID',
    :cookie_key => 'COOKIE_SECRET',
    :auth_token => 'AUTH_TOKEN',
    :css_ref => 'CSS',
    :js_ref => 'JS'
];
```
> Note: Custom logo/js/css can be added together

<a name="logging"></a>**No Blocking, Monitor Only**
Default mode: PxModule::ACTIVE_MODE

- PxModule::ACTIVE_MODE - Module blocks users crossing the predefined block threshold. Server-to-server requests are sent synchronously.

- PxModule::$MONITOR_MODE - Module does not block users crossing the predefined block threshold. The `custom_block_handler` function will be eval'd in case one is supplied, upon crossing the defined block threshold.

```ruby
params[:module_mode] = PxModule::MONITOR_MODE
```

<a name="custom-uri"></a>**Custom URI**

Default: 'REQUEST_URI'

The URI can be returned to the PerimeterX module, using a custom user function, defined on the ``params`` variable

```ruby
params[:custom_uri] = -> (request) {
  return request.headers['HTTP_X_CUSTOM_URI']
}
```

<a name="sensitive-headers"></a>**Filter sensitive headers**
A list of sensitive headers can be configured to prevent specific headers from being sent to PerimeterX servers (lower case header names). Filtering cookie headers for privacy is set by default, and can be overridden on the `params` variable.

Default: cookie, cookies

```ruby
params[:sensitive_headers] = ['cookie', 'cookies', 'secret-header']

```

<a name="api-timeout"></a>**API Timeouts**
>Note: Controls the timeouts for PerimeterX requests. The API is called when a Risk Cookie does not exist, or is expired or invalid

The API Timeout, in seconds (int), to wait for the PerimeterX server API response.

Default: 1

```ruby
params[:api_timeout] = 4
```

<a name="send-page-activities"></a>**Send Page Activities**
Default: true
A boolean flag to enable or disable sending of activities and metrics to PerimeterX on each page request. Enabling this feature will provide data that populates the PerimeterX portal with valuable information, such as the amount of requests blocked and additional API usage statistics.

```ruby
params[:send_page_activities] = false
```

<a name="additional-page-activity-handler"></a>**Additional Page Activity Handler**

Adding an additional activity handler is done by setting `additional_activity_handler` with a user defined function on the `params` variable. The `additional_activity_handler` function will be executed before sending the data to the PerimeterX portal.

Default: Only send activity to PerimeterX as controlled by `params`.



```ruby
params[:additional_activity_handler] = -> (activity_type, px_ctx, details){
    // user defined logic comes here
};
```

<a name="debug-mode"></a>**Debug Mode**
Default: false

Enables debug logging mode to STDOUT
```ruby
  params[:debug] = true
```

<a name="whitelist-routes"></a>**Whitelist Routes**
Default: []

An array of route prefixes and/or regular expressions that are always whitelisted and not validated by PerimeterX.
A string value of a path will be treated as a prefix.
A regexp value of a path will be treated as is.

```ruby
  params[:whitelist_routes] = ["/example", /\A\/example\z/]
```

<a name="update-config"></a>**Update Configuration on Runtime**

As mentioned before, PerimeterX Module should be configured in `<rails_app>/config/initializers/perimeterx.rb`.
However, it is possible to override configuration options on each request.
To do so, send the configuration options as an argument when calling to `px_verify_request` as described in the following example.
Notice that in case of an invalid argument, the module will raise an error. Therefore, when using this feature, make sure to wrap the call to `px_verify_request` with begin and rescue. It is highly recommended to log the error message to follow such errors.

Usage example:

```ruby
class HomeController < ApplicationController
  include PxModule

  before_action do call_perimeterx_verify_request end

  def call_perimeterx_verify_request
    params = {
    :blocking_score => 70,
    :module_mode => 2
    }
    begin
      px_verify_request(params) 
    rescue StandardError => e
      # $stdout.write(e.message)
    end
  end

end
```

<a name="first-party"></a>**First Party**

To enable first party on your enforcer, add the following routes to your `config/routes.rb` file:

```ruby
  get '/:appid_postfix/init.js', to: 'home#index', constraints: { appid_postfix: /XXXXXXXX/ }
  get '/:appid_postfix/captcha/:all', to: 'home#index', constraints: { appid_postfix: /XXXXXXXX/, all:/.*/ }
  post '/:appid_postfix/xhr/:all', to: 'home#index', constraints: { appid_postfix: /XXXXXXXX/, all:/.*/  }  
```

Notice that all occurences of `XXXXXXXX` should be replaced with your px_app_id without the "PX" prefix. For example, if your px_app_id is `PX2H4seK9L`, replace `XXXXXXXX` with `2H4seK9L`.

In case you are using more than one px_app_id, provide all of them with a `|` sign between them. For example:  2H4seK9L|9bMs6K94|Lc5kPMNx


First Party configuration:

Default: true

```ruby
  params[:first_party_enabled] = false
```


<a name="contributing"></a># Contributing #
------------------------------
The following steps are welcome when contributing to our project.
###Fork/Clone
First and foremost, [Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
Create a branch on your fork, preferably using a self descriptive branch name.

###Code/Run
Help improve our project by implementing missing features, adding capabilities or fixing bugs.

To run the code, simply follow the steps in the [installation guide](#installation). Grab the keys from the PerimeterX Portal, and try refreshing your page several times continously. If no default behaviours have been overriden, you should see the PerimeterX block page. Solve the CAPTCHA to clean yourself and start fresh again.
