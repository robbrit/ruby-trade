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

  def side_size heap
    # TODO: This is not accurate since if there are multiple orders at the
    # same price this will not add them up
    # However that requires a Heap#each, which does not exist yet
    heap.next ? heap.next.size : 0
  end

  def bid_size
    side_size @buy_orders
  end

  def ask_size
    side_size @sell_orders
  end

private

  def handle_buy_order order
    while not @sell_orders.empty? and order.price >= (next_order = @sell_orders.next).price
      # buy order is at least equal to the ask, at least one trade will trigger
      if order.size > next_order.size
        # Took out the entire order, keep going
        price, size = next_order.price, next_order.size
        next_order.fill! price, size
        order.fill! price, size
        @sell_orders.pop
        @last = next_order.price
      else
        # This one is enough to fill the sent one, no need to add it
        orig_size = next_order.size
        price, size = next_order.price, order.size
        next_order.fill! price, size
        order.fill! price, size
        @sell_orders.pop if size == orig_size
        @last = next_order.price
        break
      end
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
        price, size = next_order.price, next_order.size
        next_order.fill! price, size
        order.fill! price, size
        @buy_orders.pop
        @last = next_order.price
      else
        # This one is enough to fill the sent one, no need to add it
        orig_size = next_order.size
        price, size = next_order.price, order.size
        next_order.fill! price, size
        order.fill! price, size

        @last = next_order.price
        @buy_orders.pop if orig_size == size
        break
      end
    end

    # if we still have size, add it to the book
    if order.size > 0
      @sell_orders.push order
    end
  end
end
