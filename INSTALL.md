# Installing ruby-trade client gem

See [README](https://github.com/robbrit/ruby-trade/blob/master/README.md) for
instructions on installing the ruby-trade server and client with Vagrant.

Alternatively, the following are instructions for manual installation.

* `ruby --version` must be 1.9.x or higher
* zeromq must be installed

On *ubuntu*:

    sudo apt-get install ruby1.9.3
    sudo apt-get install build-essential libzmq-dev
    sudo gem install ruby-trade

On *OS X*:

* install [homebrew](http://brew.sh/)
* to upgrade ruby, see discussion at http://stackoverflow.com/q/8730676/9621
* Then do the following:

    brew install homebrew/versions/zeromq22
    sudo gem install ruby-trade

*Running the client*:

At this point you can clone the repo and test the client:

    git clone https://github.com/robbrit/ruby-trade.git
    cd ruby-trade

    # edit example-client/client.rb to change server IP (defaults to 127.0.0.1)
    ruby example-client/client.rb
