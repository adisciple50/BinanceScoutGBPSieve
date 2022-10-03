require 'binance'
require 'parallel'

RESULTING_CURRENCY = 'GBP'
RESULTING_CURRENCY_REGEX = /GBP$/
BLACKLIST = ["SHIBBTC","BTCSHIB","SHIBGBP"]

# put your api key and secret in these Environmental variables on your system
binance = Binance::Client::REST.new(api_key:ENV['binance-scout-key'],secret_key:ENV['binance-scout-secret'])

ORDER_BOOK = binance.book_ticker.delete_if(){|pair| BLACKLIST.include?(pair["symbol"])}

RESULTING_CURRENCY_ORDERS = ORDER_BOOK.select{|order| order['symbol'].match(RESULTING_CURRENCY_REGEX)}

def sorted_orders(resulting_currency_orders)
  result = resulting_currency_orders.sort_by(){|order| order['askPrice'].to_f <=> order['askPrice'].to_f}
  return result
end

def highest_value(order_set)
  order_set[-1]
end

def cheapest_pair(order_set)
  order_set[0]
end

RESULTING_CURRENCY_SORTED_ORDERS = sorted_orders(RESULTING_CURRENCY_ORDERS)

trade1 = cheapest_pair RESULTING_CURRENCY_SORTED_ORDERS

def intermediate_step(trade1,trade3,order_set,resulting_currency)
  pair1 = trade1['symbol'].delete_prefix(resulting_currency).delete_suffix(resulting_currency)
  pair2 = trade3['symbol'].delete_prefix(resulting_currency).delete_suffix(resulting_currency)


  order_set.select(){|order| order['symbol'].match?("#{pair1}#{pair2}") || order['symbol'].match?("#{pair2}#{pair1}")}
end

trade3 = highest_value RESULTING_CURRENCY_SORTED_ORDERS

trade2 = intermediate_step(trade1,trade3,ORDER_BOOK,RESULTING_CURRENCY)
puts trade1
puts trade2
puts trade3
result = { trade1["symbol"] => trade1["askPrice"] , trade2["symbol"] => trade2["askPrice"] ,trade3["symbol"] => trade3["askPrice"], "result" => trade1["askPrice"].to_f * trade2["askPrice"].to_f * trade3["askPrice"].to_f}
puts result