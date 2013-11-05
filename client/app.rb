require_relative 'client'

class MyApp
  include RubyTrade::Client

  def self.on_connect *args
    puts "sending order"
    @buy_order = buy 100, at: 10.0
  end

  def self.on_tick *args
    puts "Cash: #{cash}"
    puts "Stock: #{stock}"
  end

  def self.on_fill *args
    puts "Got filled"
  end

  def self.on_partial_fill *args
    puts "Got partially filled"
    @buy_order.cancel!
  end

end

MyApp.connect_to "127.0.0.1", as: "Jim"
