# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # ruby-trade/server/webserver
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # ruby-trade/server/feed
  config.vm.network "forwarded_port", guest: 9000, host: 9000

  # ruby-trade/server/order is on 9001
  config.vm.network "forwarded_port", guest: 9001, host: 9001

  # ruby-trade/server feed
  config.vm.provision :shell, :inline => <<-EOH
    apt-get update
    # ruby-trade depends on 1.9.3
    apt-get install -y ruby1.9.3 vim curl git build-essential

    apt-get install libzmq-dev -y

    # install server gems
    gem install bundler
    cd /vagrant/server
    bundle install

    # install client gem
    gem install ruby-trade
  EOH
end
