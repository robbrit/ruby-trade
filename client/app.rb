require_relative 'client'

class MyApp
  include RubyTrade::Client

  def self.on_connect *args
    puts "sending order"
    buy 100, at: 10.0
  end

  def self.on_tick *args
    puts "tick"
    puts args

    if not @sent
      @sent = true
      sell 50, at: 10.0
    end
  end

  def self.on_fill *args
    puts "fill"
    puts args
  end

  def self.on_partial_fill *args
    puts "partial fill"
    puts args
  end

end

MyApp.connect_to "127.0.0.1", as: "Jim"
