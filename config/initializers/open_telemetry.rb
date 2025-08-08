require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/rails'
require 'opentelemetry/instrumentation/rack'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/sdk/metrics'
#require 'opentelemetry/exporter/otlp/metrics'
require 'logger'

def parse_resource_attributes(attr_string)
  return {} if attr_string.nil?

  attr_string.split(',').each_with_object({}) do |pair, hash|
    key, value = pair.split('=')
    hash[key] = value
  end
end

resource_attrs = parse_resource_attributes(ENV['OTEL_RESOURCE_ATTRIBUTES'])

# Configure OpenTelemetry SDK internal logging to file
otel_log_file = Rails.root.join('log', 'opentelemetry_sdk.log')
OpenTelemetry.logger = Logger.new(otel_log_file, 'daily')
OpenTelemetry.logger.level = Logger::DEBUG

OpenTelemetry::SDK.configure do |c|
  SCR = OpenTelemetry::SemanticConventions::Resource

  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    # setting these would take precedence over things set in the OTEL_RESOURCE_ATTRIBUTES env var
    SCR::DEPLOYMENT_ENVIRONMENT => resource_attrs[SCR::DEPLOYMENT_ENVIRONMENT] || Rails.env.to_s,
    SCR::K8S_NAMESPACE_NAME => resource_attrs[SCR::K8S_NAMESPACE_NAME] || ENV.fetch('K8S_NAMESPACE_NAME', ''),
  )

  # setting this would take precedence over the OTEL_SERVICE_NAME env var
  c.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'from_config_initializer')

  c.use_all() # enables all instrumentation!
end

# This happens by default in the configuration patch
# Add a metrics reader for OTLP exporter
#metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
#periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: metric_exporter)
#OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)


OTEL_METER = OpenTelemetry.meter_provider.meter('rails-otel-demo-meter')
CUSTOMERS_INDEX_COUNTER = OTEL_METER.create_counter(
  'customers_index_accessed',
  unit: 'access',
  description: 'Number of times customers#index was accessed'
)

PROCESS_MEMORY_GAUGE = OTEL_METER.create_gauge(
  'process.memory',
  unit: 'MB',
  description: 'Memory usage of the Rails process in MB'
)

# Observable Gauge metric does not work yet
# https://github.com/open-telemetry/opentelemetry-ruby/issues/1877
#PROCESS_MEMORY_GAUGE = OTEL_METER.create_observable_gauge(
#  'process.memory.mb',
#  unit: 'MB',
#  description: 'Memory usage of the Rails process in MB',
#  callback: ->(observer) {
#    mem = GetProcessMem.new
#    observer.observe(mem.mb, {})
#  }
#)