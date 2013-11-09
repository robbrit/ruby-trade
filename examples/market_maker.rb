require "ruby-trade"

TradeAmount = 10_000
InitialPrice = 10.0
Distance = 2.0
UpdateInterval = 3

class Marketmaker
  include RubyTrade::Client

  def self.on_connect *args
    puts "Connected."

    update_orders

    this = self
    EM.add_periodic_timer UpdateInterval do
      this.update_orders
    end
  end

  def self.on_tick level1
    @level1 = level1
  end

  def self.update_orders
    @buy_order.cancel! if @buy_order
    @sell_order.cancel! if @sell_order

    last = @level1 ? @level1["last"] : InitialPrice
    last = InitialPrice if last.nil? or last == 0.0
    puts @level1
    puts last

    # buy and sell a certain percentage from the last
    buy_price = last * (1.0 - Distance / 100)
    sell_price = last * (1.0 + Distance / 100)

    puts "Buy: #{buy_price}"
    puts "Sell: #{sell_price}"

    # randomize sending order - sometimes don't send an order just to mess with
    # folks
    should_send_buy = rand > 0.1
    should_send_sell = rand > 0.1

    if should_send_buy
      @buy_order = buy TradeAmount, at: buy_price
    else
      puts "Disabling buy"
      @buy_order = nil
    end

    if should_send_sell
      @sell_order = sell TradeAmount, at: sell_price
    else
      puts "Disabling sell"
      @sell_order = nil
    end
  end

end

Marketmaker.connect_to "127.0.0.1", as: "MarketMaker", ai: true
