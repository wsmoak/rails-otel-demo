
require_relative 'rails_otel_demo/metrics'

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

