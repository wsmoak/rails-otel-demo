class CustomersController < ApplicationController

  def index
    Rails.logger.info 'START Index view accessed'

    RailsOTelDemo::Logger.log(
      'Quercus rubra',
      'acorns' => true,
      'leaves' => true,
    )

    RailsOTelDemo::Logger.log(
      'Fagus grandifolia',
      'acorns' => false,
      'foo' => 'bar',
      'customer_id' => 12345,
      'http.response.header.X-Request-ID' => request.uuid,
    )

    Rails.logger.info 'END Index view accessed'
  end
end
