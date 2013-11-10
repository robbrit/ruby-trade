# Ruby-Trade

Ruby-Trade is a game where each player builds an AI to compete against other AIs 
in a virtual stock exchange.

The way it works is just like a real stock exchange: you place orders to trade
into the market to buy or sell shares.

## Installation

Just install the gem:

    gem install ruby-trade

Mac users: some people are having some issues installing the ZeroMQ libraries
on a Mac. If you install an older version of ZeroMQ it should work:

    brew install zeromq22
    gem install ruby-trade

## Mechanics

The mechanics of the market are for the most part like a real stock market. In
ruby-trade there is only one stock, and everybody buys and sells that stock from
other players within the market.

### Orders

The only way to buy or sell shares is through orders. The client script sends
a orders to the market to buy or sell a number of shares at a specified price.
When you send an order, the server checks to see if your order can be matched
with any of the other orders and if it can be, it will execute a trade and your
script will receive a notification.

The server is real-time, there is no time interval between when things happen.
If your script sends an order, it is sent to the market immediately.

### Matching Example

Here's an example of how the server will attempt to match a new order into the
market. Suppose here are the existing orders:

* Trader A has a buy order for 5k shares at $9.00
* Trader B has a sell order for 10k shares at $10.00
* Trader C has:
  * a sell order for 2k shares at $10.00 but it was placed after trader B's order
  * a sell order for 10k shares at $10.50
  * a buy order for 10k shares at $8.00.

In this case the "best" buy order is trader A's order at $9 because it has the
highest price (picture yourself in the position of a seller, would you rather
sell your shares to someone at $9 or at $8?). This best price is called the "bid".
The best sell order on the other hand is trader B's sell order at $10, and this
is called the "ask".

Now Trader D comes along and sends a buy order for 15k shares at $12. Here's how
the server will match up the orders:

1. Trader D will buy 10k shares from trader B at $10.00 (it starts at the best
   sell price).
2. Trader D will then buy 2k shares from trader C at $10.00 (it resolves ties at
   a certain price level using a first-come-first-serve algorithm).
3. Trader D will finally buy 3k shares from trader C at $10.50. The first two
   orders at $10.00 will be gone, and trader C's order at $10.50 will be updated
   to only have 7k shares left.

When this is over, the "bid" will still be $9.00 from trader A's order, but the
"ask" will have gone up to $10.50 because all the orders at $10.00 are now gone.
The "last" price (the price that the last trade was at) would be $10.50.

Next, trader E sends a sell order for 10k shares at $8.50. The matching is like
this:

1. Trader E will sell 5k shares to trader A at $9.00 (the best buy price).
2. Since there are no more orders left that are greater than or equal to $8.50,
   trader E's order will enter the market as a sell order for 5k shares at $8.50.

The "bid" gets updated to be $8.00 (for trader C's buy order) and the "ask" gets
updated to be $8.50 (trader E's new sell order). The "last" will be $9.00.


## Lingo

Before getting started, there are a few definitions that you should know about:

* "fill" - An event triggered when one of your orders gets fully executed (that
  is, all the shares that you requested to buy or sell are bought/sold).
* "partial fill" - The same as a fill, but not all of the shares in your order
  were executed. For example if you sent an order to buy 100 shares and someone
  only sold you 50, it is called a partial fill.
* "bid" - The highest price of all the buy orders.
* "ask" - The lowest price of all the sell orders.
* "last" - The last price that some shares were traded at.
* "spread" - The difference between the bid and the ask.
* "position" - The amount of stock that you have. If it is positive then it is
  called a "long" position, if it is negative then it is called a "short" position.
  Yes, it is possible to have negative shares.
* "Level 1" - The bid, the ask, and the last.
* "Outside the market" - Any buy order with a price less than the bid or any sell
  order with a price higher than the ask is considered "outside the market."

## Client

Here is an example client:

    require 'ruby-trade'

    class MyApp
      include RubyTrade::Client

      # Called by the system when we connect to the exchange server
      def self.on_connect
        puts "sending order"
        @buy_order = buy 100, at: 10.0
      end

      # Called whenever something happens on the exchange
      def self.on_tick level1
        puts "Cash: #{cash}"
        puts "Stock: #{stock}"
        puts "Bid: #{level1["bid"]}"
        puts "Ask: #{level1["ask"]}"
        puts "Last: #{level1["last"]}"
      end

      # Called when an order gets filled
      def self.on_fill order, amount, price
        puts "Order ID #{order.id} was filled for #{amount} shares at $%.2f" % price
      end

      # Called when an order gets partially filled
      def self.on_partial_fill order, amount, price
        puts "Order ID #{order.id} was partially filled for #{amount} shares at $%.2f" % price

        # Cancel the order
        @buy_order.cancel!
      end

    end

    # Connect to the server
    MyApp.connect_to "127.0.0.1", as: "Jim"

### Hooks

The following hooks are available:

* `on_connect` - Called when the client connects to the server.
* `on_tick level` - Called whenever something happens in the exchange. `level1`
  is a hash containing `"bid"`, `"ask"`, and `"last"`.
* `on_fill order, amount, price` - Called when `order` is filled. `amount` is
  the amount (usually the size of the order, but will be less if the order was
  partially filled before), and `price` is the price that it was filled at.
* `on_partial_fill order, amount, price` - Same as `on_fill`, but this order is
  still live in the market.
* `on_dividend amount` - Called when a dividend is received, `amount` is the
  cash value of the dividend (which will be negative for short positions).

## Events

### Dividend

Every half hour, a dividend is paid out. Anybody who has a long position will
gain cash equal to the dividend times the number of shares that they own; anybody
with a short position will lose cash equal to the dividend times the number of
shares that they are short.

### Big Trades

At random times during the trading session, a large trade may be made. These trades
will be set at some price outside the market, the distance determined randomly.
These trades do not count towards the score.

### Market Makers

While not really an event, there will be a number of traders in the market who
are designated as "market makers." They keep buy orders and sell orders a little
bit outside the market to ensure that there is usually someone there to buy when
people want to sell, or sell when people want to buy. Note that they are not
always there, so traders should not rely on them being there. They are not there
to make money and do not count towards the score.
