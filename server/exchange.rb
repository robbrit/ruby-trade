require_relative 'account'
require_relative 'order-book'
require_relative 'order'
require_relative 'server'

STARTING_EQUITY = 0
STARTING_CASH = 10_000

class Exchange
  def initialize
    @accounts = {}
    @orders = {}
    @order_no = 0
    @book = OrderBook.new
  end

  def identify data
    account = @accounts[data["peer_name"]] || Account.new(data["peer_name"], data["name"], STARTING_EQUITY, STARTING_CASH)

    account.update_name data["name"]

    @accounts[account.name] = account

    account
  end

  def new_order account, data
    id = @order_no += 1
    order = Order.new id, data["local_id"], data["side"], data["price"],
      data["size"], account.id

    if not order.valid?
      return order.errors, order
    else
      return nil, order
    end
  end

  # Send an order
  def send_order order
    order.status = :accepted
    @book.send_order order
  end

  def level1
    {
      bid: @book.bid,
      ask: @book.ask,
      last: @book.last
    }
  end
end
