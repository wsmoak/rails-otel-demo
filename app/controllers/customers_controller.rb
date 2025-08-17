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

    CUSTOMERS_INDEX_COUNTER.add(
        1,
        attributes: {
            'host.name' => Socket.gethostname,
            'controller' => 'customers',
            'action' => 'index',
            'fruit' => the_fruit,
        }
    )

    Rails.logger.info "Temporality preference is #{ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE']}"

    mem = GetProcessMem.new
    Rails.logger.info "Memory usage: #{mem.mb} MB"

    PROCESS_MEMORY_GAUGE.record(
        mem.mb,
        attributes: {
            'host.name' => Socket.gethostname,
            'process.id' => Process.pid,
            "thread.id" => Thread.current.object_id
        }
    )

    Rails.logger.info 'END Index view accessed'
  end
end
