require_relative "../order-book"
require_relative "../order"

class Observer
  attr_reader :updates, :last_args

  def initialize
    @updates = 0
  end

  def update *args
    @updates += 1
    @last_args = args
  end
end

describe OrderBook do
  before :each do
    @book = OrderBook.new

    @book_obs = Observer.new
    @book.add_observer @book_obs
  end

  it "should enter buy orders" do
    @book.send_order Order.new(1, 1, "buy", 9.00, 100, 1)
    @book.send_order Order.new(1, 1, "buy", 10.00, 100, 1)
    @book.send_order Order.new(1, 1, "buy", 9.5, 100, 1)

    @book.bid.should == 10.0
    @book.ask.should == 0.0
    @book.bid_size.should == 100
    @book.ask_size.should == 0

    @book_obs.updates.should == 3
  end

  it "should enter sell orders" do
    @book.send_order Order.new(1, 1, "sell", 11.00, 100, 1)
    @book.send_order Order.new(1, 1, "sell", 10.00, 100, 1)
    @book.send_order Order.new(1, 1, "sell", 10.50, 100, 1)

    @book.bid.should == 0.0
    @book.ask.should == 10.0
    @book.bid_size.should == 0
    @book.ask_size.should == 100
    @book_obs.updates.should == 3
  end

  it "should trigger a fill" do
    buy_order = Order.new(1, 1, "buy", 10.00, 100, 1)
    buy_obs = Observer.new
    buy_order.add_observer buy_obs

    @book.send_order buy_order

    # Send a sell order to hit the bid
    sell_order = Order.new(1, 1, "sell", 9.80, 100, 1)
    sell_obs = Observer.new
    sell_order.add_observer sell_obs

    @book.send_order sell_order

    # Should have taken out both orders
    @book.bid.should == 0.0
    @book.bid_size.should == 0
    @book.ask.should == 0.0
    @book.ask_size.should == 0
    @book.last.should == 10.00

    buy_obs.updates.should == 1
    buy_obs.last_args.should =~ [:fill, buy_order, 100, 10.00]
    sell_obs.updates.should == 1
    sell_obs.last_args.should =~ [:fill, sell_order, 100, 10.00]
  end

  it "should trigger a partial fill" do
    buy_order = Order.new(1, 1, "buy", 10.00, 100, 1)
    buy_obs = Observer.new
    buy_order.add_observer buy_obs

    @book.send_order buy_order

    # Send a sell order to hit the bid
    sell_order = Order.new(1, 1, "sell", 9.80, 50, 1)
    sell_obs = Observer.new
    sell_order.add_observer sell_obs

    @book.send_order sell_order

    # Should have taken out both orders
    @book.bid.should == 10.00
    @book.bid_size.should == 50
    @book.ask.should == 0.0
    @book.ask_size.should == 0
    @book.last.should == 10.00

    buy_obs.updates.should == 1
    buy_obs.last_args.should =~ [:partial_fill, buy_order, 50, 10.00]
    sell_obs.updates.should == 1
    sell_obs.last_args.should =~ [:fill, sell_order, 50, 10.00]
  end

  it "should cancel an order" do
    buy_order = Order.new(1, 1, "buy", 10.00, 100, 1)
    buy_obs = Observer.new
    buy_order.add_observer buy_obs

    @book.send_order buy_order

    @book.cancel_order buy_order

    @book.bid.should == 0.0
    buy_order.status.should == :cancelled
    buy_obs.updates.should == 1
    buy_obs.last_args.should =~ [:cancel, buy_order]
  end
end
