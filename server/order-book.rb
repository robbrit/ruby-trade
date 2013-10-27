require 'observer'
require 'algorithms'

class OrderBook
  include Observable

  attr_reader :last

  def initialize
    @buy_orders = Containers::MaxHeap.new
    @sell_orders = Containers::MinHeap.new
    @last = 0.0
  end

  def send_order order
    changed
    notify_observers :new, order

    if order.side.to_s == "buy"
      handle_buy_order order
    else
      handle_sell_order order
    end
  end

  def cancel_order order
    changed
    notify_observers :cancel, order

    if order.side.to_s == "buy"
      @buy_orders.delete order
    else
      @sell_orders.delete order
    end

    order.cancel!
  end

  def bid
    @buy_orders.empty? ? 0.0 : @buy_orders.next.price
  end

  def ask
    @sell_orders.empty? ? 0.0 : @sell_orders.next.price
  end

private

  def handle_buy_order order
    while not @sell_orders.empty? and order.price >= (next_order = @sell_orders.next).price
      # buy order is at least equal to the ask, at least one trade will trigger
      if order.size > next_order.size
        # Took out the entire order, keep going
        next_order.fill! next_order.size
        order.fill! next_order.size
        @sell_orders.pop
      else
        # This one is enough to fill the sent one, no need to add it
        next_order.fill! order.size
        order.fill! order.size
        break
      end

      @last = next_order.price
    end

    # if we still have size, add it to the book
    if order.size > 0
      @buy_orders.push order
    end
  end

  def handle_sell_order order
    while not @buy_orders.empty? and order.price <= (next_order = @buy_orders.next).price
      if order.size > next_order.size
        # Took out the entire order, keep going
        next_order.fill! next_order.size
        order.fill! next_order.size
        @buy_orders.pop
      else
        # This one is enough to fill the sent one, no need to add it
        next_order.fill! order.size
        order.fill! order.size
        break
      end

      @last = next_order.price
    end

    # if we still have size, add it to the book
    if order.size > 0
      @sell_orders.push order
    end
  end
end
