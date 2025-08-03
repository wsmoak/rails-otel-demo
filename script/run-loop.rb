require 'net/http'
require 'uri'

NUM_REQUESTS = 1000
URL = 'http://localhost:3001/customers'

NUM_REQUESTS.times do |i|
  uri = URI(URL)
  begin
    response = Net::HTTP.get_response(uri)
    puts "Request: #{i} Status: #{response.code}"
  rescue => e
    puts "Request: #{i} Error: #{e.class} - #{e.message}"
  end
  sleep(rand(1..10))
end