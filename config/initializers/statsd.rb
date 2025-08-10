# Configure StatsD client for Rails
#require 'statsd-instrument'

#StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new('localhost:8125')
#StatsD.prefix = 'rails_otel_demo'

# Optionally, you can use environment variables for host/port/prefix
# StatsD.backend = StatsD::Instrument::Backend::UDPBackend.new(ENV.fetch('STATSD_HOST', 'localhost:8125'))
# StatsD.prefix = ENV.fetch('STATSD_PREFIX', 'rails_otel_demo')

#StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new(ENV.fetch#('STATSD_HOST', 'localhost:8125'))
#StatsD.prefix = 'rails_otel_demo'

# Configure the global Datadog StatsD client
$statsd = Datadog::Statsd.new(
  ENV.fetch('STATSD_HOST', '127.0.0.1'),
  ENV.fetch('STATSD_PORT', 8125),
  namespace: ENV.fetch('STATSD_NAMESPACE', 'rails_otel_demo'),
  logger: Logger.new(Rails.root.join('log', 'statsd.log'), 'daily')
)
