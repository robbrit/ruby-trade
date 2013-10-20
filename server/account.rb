class Account
  attr_reader :stock, :money, :name
  
  def initialize name, stock, money
    @name, @stock, @money = name, stock, money
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
