# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ubuntu:14.04
RUN apt-get update && apt-get --force-yes -qq -y install \
    build-essential \
    ca-certificates \
    curl \
    git \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libgdbm-dev \
    libtool \
    automake \
    bison \
    lua-cjson \
    libncurses5-dev \
    m4 \
    libsqlite3-dev \
    rsyslog \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    python-software-properties \
    libffi-dev \
    nodejs \
    wget \
    zlib1g-dev

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable --rails"
RUN /bin/bash -l -c "rvm install 2.3.0"
RUN /bin/bash -l -c "rvm use 2.3.0"
RUN /bin/bash -l -c "gem install bundler"
RUN /bin/bash -l -c "gem install rails -v 4.2.0"
RUN mkdir -p /tmp/ruby_sandbox
WORKDIR /tmp/ruby_sandbox
WORKDIR /tmp/ruby_sandbox
RUN /bin/bash -l -c "rails new webapp"
WORKDIR /tmp/ruby_sandbox/webapp
RUN /bin/bash -l -c "rails generate controller home index"
RUN mkdir /tmp/ruby_sandbox/perimeterx-ruby-sdk
COPY ./ /tmp/ruby_sandbox/perimeterx-ruby-sdk
WORKDIR /tmp/ruby_sandbox/perimeterx-ruby-sdk
RUN /bin/bash -l -c "gem build perimeter_x.gemspec"
RUN /bin/bash -l -c "bundler install"
RUN /bin/bash -l -c "gem install --local perimeter_x"
WORKDIR /tmp/ruby_sandbox/webapp
RUN sed -i "2i gem 'perimeter_x', :path => '/tmp/ruby_sandbox/perimeterx-ruby-sdk'" /tmp/ruby_sandbox/webapp/Gemfile
EXPOSE 3000
CMD /bin/bash -l -c "rails s"
