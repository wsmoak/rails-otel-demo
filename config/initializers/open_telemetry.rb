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

# This happens by default in the configuration patch and does not need to be done here.
#
# metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
# periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: metric_exporter)
# OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)


OTEL_METER = OpenTelemetry.meter_provider.meter('rails-otel-demo-meter')

PROCESS_MEMORY_OBSERVED_GAUGE = OTEL_METER.create_observable_gauge(
  'process.memory.observed',
  unit: 'MB',
  description: 'Memory usage of the process in MB',
  callback: -> {
    mem = GetProcessMem.new
    puts "THE CALLBACK WAS CALLED! #{Time.now} pid: #{Process.pid} tid: #{Thread.current.object_id} mem: #{mem.mb}"
    mem.mb
  }
)

# This calls 'update' as well as recording an observation
PROCESS_MEMORY_OBSERVED_GAUGE.observe(
    timeout: 30, # seconds?
    attributes: {
      "host.name" => Socket.gethostname,
      "process.id" => Process.pid,
      "thread.id" => Thread.current.object_id
    }
)
