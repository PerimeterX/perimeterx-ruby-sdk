# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ruby:2.3.0

RUN apt-get update && apt-get --force-yes -qq -y install \
 nodejs
ENV RAILS_VERSION 4.2.0
RUN gem install rails --version "$RAILS_VERSION"
RUN gem install bundler
RUN mkdir -p /tmp/ruby_sandbox
WORKDIR /tmp/ruby_sandbox
RUN git clone https://github.com/PerimeterX/perimeterx-ruby-sdk.git
RUN rails new webapp
WORKDIR /tmp/ruby_sandbox/webapp

RUN rails generate controller home index
WORKDIR /tmp/ruby_sandbox/webapp
EXPOSE 3000
RUN sed -i '2i gem "perimeter_x", :path => "/tmp/ruby_sandbox/perimeterx-ruby-sdk"' /tmp/ruby_sandbox/webapp/Gemfile
RUN bundler update
COPY ./examples/ /tmp/ruby_sandbox/webapp
CMD ["rails","server","-b","0.0.0.0"]
