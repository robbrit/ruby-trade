require "ruby-trade"

TradeAmount = 50_000
InitialPrice = 10.0
Distance = 2.0

class Marketmaker
  include RubyTrade::Client

  def self.on_connect *args
    puts "Connected."

    update_orders

    this = self
    EM.add_periodic_timer 5 do
      this.update_orders
    end
  end

  def self.on_tick level1
    @level1 = level1
  end

  def self.update_orders
    @buy_order.cancel! if @buy_order
    @sell_order.cancel! if @sell_order

    last = @level1 ? @level1[:last] : InitialPrice
    last ||= InitialPrice

    # buy and sell a certain percentage from the last
    buy_price = last * (1.0 - Distance / 100)
    sell_price = last * (1.0 + Distance / 100)

    @buy_order = buy TradeAmount, at: buy_price
    @sell_order = sell TradeAmount, at: sell_price
  end

end

Marketmaker.connect_to "127.0.0.1", as: "MarketMaker", ai: true
