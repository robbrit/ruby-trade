require 'observer'

class Account
  include Observable

  attr_reader :id, :stock, :cash, :name
  
  def initialize id, name, stock, cash
    @id, @name, @stock, @cash = id, name, stock, cash
  end

  def update_name name
    if @name != name
      @name = name
      changed
      notify_observers
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
end
