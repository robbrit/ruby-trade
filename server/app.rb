require_relative 'order-book'

class App
  def initialize
    @accounts = {}
    @orders = {}
    @book = OrderBook.new
  end
end
