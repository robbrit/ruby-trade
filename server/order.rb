require 'observable'

class Order
  include Observable

  attr_reader :id, :side, :price, :size, :owner, :sent_at

  def initialize id, side, price, size, owner
    @id, @side, @price, @size, @owner = id, side, price, size, owner
    @sent_at = Time.now
    @cancelled = false
  end

  def <=> order
    if order.price == price
      @sent_at <=> order.sent_at
    else
      price <=> order.price
    end
  end

  def cancelled?
    @cancelled
  end

  def fill! amount
    changed

    status = :fill
    status = :partial_fill if amount < @size

    @size -= amount
    
    notify_observers status, self
  end

  def cancel!
    @cancelled = true
    changed
    notify_observers :cancel, self
  end
end
