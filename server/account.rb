require 'observer'

class Account
  include Observable

  attr_reader :id, :stock, :money, :name
  
  def initialize id, name, stock, money
    @id, @name, @stock, @money = id, name, stock, money
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
      @money -= order.price * amount
    else
      @stock -= amount
      @money += order.price * amount
    end
  end

  def net_value current_price
    @money + @stock * current_price
  end
end
