require 'observer'

class Order
  include Observable

  attr_reader :id, :local_id, :side, :price, :size, :sent_at, :status

  def initialize id, side, price, size
    @id, @side, @price, @size = id, side, price, size
    @sent_at = Time.now
    @cancelled = false
    @status = :pending_accept
  end

  def status= new_status
    @status = new_status
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
