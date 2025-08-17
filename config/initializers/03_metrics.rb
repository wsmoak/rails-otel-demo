
require_relative '../../lib/rails_otel_demo/metrics'

RailsOTelDemo::Metrics.create_counter(
  'controller_access',
  unit: 'requests',
  description: 'Number of times customers#index was accessed'
)

RailsOTelDemo::Metrics.create_gauge(
  'process.memory',
  unit: 'MB',
  description: 'Memory usage of the Rails process in MB'
)

RailsOTelDemo::Metrics.create_observable_gauge(
  'process.memory.observed',
  unit: 'MB',
  description: 'Memory usage of the process in MB',
  callback: -> {
    mem = GetProcessMem.new
    puts "THE CALLBACK WAS CALLED! #{Time.now} pid: #{Process.pid} tid: #{Thread.current.object_id} mem: #{mem.mb}"
    mem.mb
  }
)

RailsOTelDemo::Metrics.observe(
    'process.memory.observed',
    timeout: 30, # seconds?
    attributes: {
      "host.name" => Socket.gethostname,
      "process.id" => Process.pid,
      "thread.id" => Thread.current.object_id
    }
)