require 'observer'

class Order
  include Observable

  attr_reader :id, :local_id, :side, :price, :size, :owner, :sent_at,
    :initial_size, :status

  def initialize id, local_id, side, price, size, owner
    @id, @local_id, @side, @price, @size, @owner = id, local_id, side, price, size, owner
    @initial_size = @size
    @sent_at = Time.now
    @status = :pending_accept

    # normalize the price to be within cents
    @price = @price.round 2
  end

  def <=> order
    if order.price == price
      @sent_at <=> order.sent_at
    else
      price <=> order.price
    end
  end

  def fill! price, amount
    changed

    status = :fill
    status = :partial_fill if amount < @size

    @size -= amount
    @status = status
    
    notify_observers status, self, price, amount
  end

  def cancel!
    @status = :cancelled
    changed
    notify_observers :cancel, self
  end

  def valid?
    errors.length > 0
  end

  def status= new_status
    @status = new_status
  end

  def errors
    errors = []

    errors << "Price must be a number" unless @price.is_a? Integer
    errors << "Price must be strictly positive" unless @price > 0
    errors << "Unknown side '#{@side}'" unless ["buy", "sell"].include? @side
    errors << "Size must be strictly positive" unless @size > 0

    errors
  end
end
