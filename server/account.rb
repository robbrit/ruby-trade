require 'observer'

class Account
  include Observable

  attr_reader :id, :stock, :cash, :name
  attr_accessor :ai
  
  def initialize id, name, stock, cash
    @id, @name, @stock, @cash = id, name, stock, cash
    @ai = false
  end

  def process_dividend amount
    value = stock * amount

    @cash += value

    changed
    notify_observers :dividend, {amount: amount, value: value}
  end

  def update_name name
    if @name != name
      @name = name
      changed
      notify_observers :name_change, name
    end
  end

  def on_trade order, amount
    if order.side == :buy
      @stock += amount
      @cash -= order.price * amount
    else
      @stock -= amount
      @cash += order.price * amount
    end
  end

  def net_value current_price
    @cash + @stock * current_price
  end

  def ai?
    @ai
  end
end
