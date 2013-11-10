require_relative 'account'
require_relative 'order-book'
require_relative 'order'
require_relative 'server'

StartingEquity = 0
StartingCash = 10_000
DividendAmount = 0.25
DividendFrequency = 600

class Exchange
  def initialize
    @accounts = {}
    @orders = {}
    @order_no = 0
    @book = OrderBook.new
  end

  def accounts
    @accounts.values
  end

  # Pay dividends to all accounts
  def pay_dividends
    @accounts.values.each do |account|
      account.process_dividend DividendAmount
    end
  end

  def identify data
    account = @accounts[data["peer_name"]] || Account.new(data["peer_name"], data["name"], StartingEquity, StartingCash)

    account.ai = data["ai"]
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
      @orders[id] = order
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

  def cancel_order order
    @book.cancel_order order if order
  end
end
