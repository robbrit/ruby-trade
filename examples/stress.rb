require 'ruby-trade'

TradeAmount = 20_000
NumOrders = 2000
InitialPrice = 10.0

class Slammer
  include RubyTrade::Client
  
  def self.on_connect *args
    puts "Connected."

    hit_it
  end

  def self.hit_it
    @orders = (1..NumOrders).map do
      buy 100, at: InitialPrice
    end

    EM.add_timer 1 do
      @orders.each do |order|
        order.cancel!
      end

      EM.add_timer 0.5 do
        hit_it
      end
    end
  end

  def self.on_tick level1
    @level1 = level1
  end
end

Slammer.connect_to "127.0.0.1", as: "Slammer", ai: true
