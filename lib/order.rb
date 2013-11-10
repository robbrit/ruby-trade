require 'observer'

class Order
  include Observable

  attr_reader :id, :side, :size, :sent_at, :status
  attr_accessor :price, :status

  def initialize id, side, price, size
    @id, @side, @price, @size = id, side, price, size
    @sent_at = Time.now
    @cancelled = false
    @status = :pending_accept

    @price = @price.round 2
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
    return if @cancelled  # can only cancel an order once

    @cancelled = true
    changed
    notify_observers :cancel, self
  end
end
