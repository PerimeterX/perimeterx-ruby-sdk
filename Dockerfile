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
RUN /bin/bash -l -c "rails new webapp"
WORKDIR /tmp/ruby_sandbox/webapp
RUN /bin/bash -l -c "rails generate controller home index"
WORKDIR /tmp/ruby_sandbox/webapp
EXPOSE 3000
RUN sed -i "2i gem 'perimeter_x', '~> 1.0.3.pre.alpha'" /tmp/ruby_sandbox/webapp/Gemfile
RUN /bin/bash -l -c "bundler update"
RUN /bin/bash -l -c "gem list|grep peri"
CMD ["/bin/bash", "-l", "-c", "rails server -b 0.0.0.0;"]
