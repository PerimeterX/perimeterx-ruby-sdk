# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ruby:2.7.1

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y --no-install-recommends nodejs yarn vim

ENV RAILS_VERSION 6.0.3.2
RUN gem install rails --version "$RAILS_VERSION"
RUN gem install bundler
RUN mkdir -p /tmp/ruby_sandbox
WORKDIR /tmp/ruby_sandbox
COPY lib /tmp/ruby_sandbox/lib
COPY Gemfile /tmp/ruby_sandbox/
COPY perimeter_x.gemspec /tmp/ruby_sandbox/
COPY Rakefile /tmp/ruby_sandbox/
RUN rails new webapp
WORKDIR /tmp/ruby_sandbox/webapp

RUN rails generate controller home index
WORKDIR /tmp/ruby_sandbox/webapp
EXPOSE 3000
RUN sed -i '2i gem "perimeter_x", :path => "/tmp/ruby_sandbox"' /tmp/ruby_sandbox/webapp/Gemfile
RUN bundler update
COPY ./dev/site/ /tmp/ruby_sandbox/webapp
CMD ["rails","server","-b","0.0.0.0"]
