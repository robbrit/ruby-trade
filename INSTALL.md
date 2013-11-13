# Installing ruby-trade

See [README](https://github.com/robbrit/ruby-trade/blob/master/README.md) for
instructions on installing the ruby-trade server and client with Vagrant.

Alternatively, the following are instructions for manual installation.

## Installing ruby 1.9+

ruby-trade requires ruby to be at least

## Installing zero-mq

### Ubuntu

These instructions were adapted from
[this page](http://ianrumford.github.io/blog/2012/09/12/installing-zeromq-2-dot-2-0-with-the-ruby-gem-on-ubuntu-12-dot-04/).

ruby-trade depends on zeromq libraries being installed on your system. 2.2.x
works best. The following [installs it from
source](http://zeromq.org/intro:get-the-software) on Debian/Ubuntu systems:
    
    sudo apt-get install -y libtool autoconf automake uuid-dev
    wget http://download.zeromq.org/zeromq-2.2.0.tar.gz
    tar xzvf zeromq-2.2.0.tar.gz
    cd zeromq-2.2.0/
    ./configure
    make
    sudo make install
    sudo ldconfig

Alternatively the following installs it from an Ubuntu PPA maintained by
chris-lea:

    apt-get install python-software-properties -y
    add-apt-repository ppa:chris-lea/zeromq -y
    add-apt-repository ppa:chris-lea/libpgm -y
    apt-get update
    apt-get install -y libzmq-dbg libzmq-dev libzmq1

## OS X

On OSX, you can install it with [homebrew](http://brew.sh/):

    brew install homebrew/versions/zeromq22

## Installing the client locally

Afterward the zeromq libraries are installed, simply do the following:

    gem install ruby-trade
