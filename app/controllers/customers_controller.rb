class CustomersController < ApplicationController

  def index
    Rails.logger.info 'START Index view accessed'

    the_fruit = ['peach', 'apple', 'cherry', 'banana'].sample

    RailsOTelDemo::Logger.log(
      'A descriptive log message',
      'acorns' => [true,false].sample,
      'customer_id' => rand(1..9_999),
      'fruit' => the_fruit,
      'original_fruit' => the_fruit
    )


    meter = OpenTelemetry.meter_provider.meter('rails-otel-demo-meter')
    counter = meter.create_counter('customers_index_accessed', unit: 'access', description: 'Number of times customers#index was accessed')
    Rails.logger.info "ABOUT TO ADD TO THE COUNTER"

    puts "THE COUNTER IS #{counter.inspect}"

    counter.add(1, attributes: { 'controller' => 'customers', 'action' => 'index' })

    Rails.logger.info 'END Index view accessed'
  end
end
