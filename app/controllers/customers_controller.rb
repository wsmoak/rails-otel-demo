class CustomersController < ApplicationController

  def index
    Rails.logger.info 'START Index view accessed'

    the_fruit = ['peach', 'apple', 'cherry', 'banana'].sample
    customer_id = rand(1..9_999)

    RailsOTelDemo::Logger.log(
      'A descriptive log message',
      'acorns' => [true,false].sample,
      'customer_id' => customer_id,
      'fruit' => the_fruit,
      'original_fruit' => the_fruit
    )

    puts "THE COUNTER IS #{RAILS_OTEL_CUSTOMERS_INDEX_COUNTER.inspect}"
    puts "ABOUT TO ADD TO THE RAILS_OTEL_CUSTOMERS_INDEX_COUNTER"
    RAILS_OTEL_CUSTOMERS_INDEX_COUNTER.add(
        1,
        attributes: {
            'controller' => 'customers',
            'action' => 'index',
            'fruit' => the_fruit,
            'customer_id' => customer_id,
        }
    )

    mem = GetProcessMem.new
    Rails.logger.info "Memory usage: #{mem.mb} MB"

    Rails.logger.info 'END Index view accessed'
  end
end
