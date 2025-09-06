
require_relative '../../lib/rails_otel_demo/metrics'

RailsOTelDemo::Metrics.observe(
    'process.memory.observed',
    timeout: 30, # seconds?
    attributes: {
      "host.name" => Socket.gethostname,
      "process.id" => Process.pid,
      "thread.id" => Thread.current.object_id
    }
)