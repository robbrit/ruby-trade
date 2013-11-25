require 'ruby-trade'

class MyApp
  include RubyTrade::Client

  # Called by the system when we connect to the exchange server
  def self.on_connect
    puts "sending order"
    @buy_order = buy 100, at: 10.0
  end

  # Called whenever something happens on the exchange
  def self.on_tick level1
    puts "Cash: #{cash}"
    puts "Stock: #{stock}"
    puts "Bid: #{level1["bid"]}"
    puts "Ask: #{level1["ask"]}"
    puts "Last: #{level1["last"]}"
  end

  # Called when an order gets filled
  def self.on_fill order, amount, price
    puts "Order ID #{order.id} was filled for #{amount} shares at $%.2f" % price
  end

  # Called when an order gets partially filled
  def self.on_partial_fill order, amount, price
    puts "Order ID #{order.id} was partially filled for #{amount} shares at $%.2f" % price

    # Cancel the order
    @buy_order.cancel!
  end

end

# Connect to the server
MyApp.connect_to "127.0.0.1", as: "Jim"
