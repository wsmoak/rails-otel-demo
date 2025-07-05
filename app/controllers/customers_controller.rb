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

    Rails.logger.info 'END Index view accessed'
  end
end
