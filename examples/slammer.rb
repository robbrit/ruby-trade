require 'ruby-trade'

TradeAmount = 20_000
InitialPrice = 10.0
Distance = 2.0
MaxDistance = 4
MinTime = 30
TimeVariance = 600

class Slammer
  include RubyTrade::Client
  
  def self.level1; @level1; end

  def self.on_connect *args
    puts "Connected."

    setup_next_shot
  end

  def self.setup_next_shot
    #time_gap = MinTime + rand(TimeVariance)
    time_gap = 10
    puts "Firing in #{time_gap} seconds..."

    this = self
    order = nil
    EM.add_timer time_gap do
      shift = Distance + rand(MaxDistance)
      is_sell = rand < 0.5
      amount = TradeAmount

      base_price = this.level1 ? this.level1["last"] : InitialPrice
      base_price = InitialPrice if base_price.nil? or base_price == 0.0

      if is_sell
        price = base_price * (1.0 - shift / 100)
        puts "Selling #{amount} at %.2f" % price
        order = sell amount, at: price
      else
        price = base_price * (1.0 + shift / 100)
        puts "Buying #{amount} at %.2f" % price
        order = buy amount, at: price
      end

      EM.add_timer 0.1 do
        puts "cancelling"
        order.cancel!
        this.setup_next_shot
      end
    end
  end

  def self.on_tick level1
    @level1 = level1
  end
end

Slammer.connect_to "127.0.0.1", as: "Slammer", ai: true
