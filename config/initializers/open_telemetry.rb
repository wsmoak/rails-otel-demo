require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rails"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/exporter/otlp"
require "opentelemetry/sdk/metrics"
# require 'opentelemetry/exporter/otlp/metrics'
require "logger"

# Patch Logger to bridge logs to OpenTelemetry
module LoggerOTelBridge
  attr_writer :skip_otel_emit

  def format_message(severity, datetime, progname, msg)
    formatted_message = super
    return formatted_message if skip_otel_emit?

    OpenTelemetry.logger_provider.logger(
      name: "rails-otel-demo",
      version: "1.0.0"
    ).on_emit(
      severity_text: severity,
      severity_number: severity_number(severity),
      timestamp: datetime,
      body: msg,
      context: OpenTelemetry::Context.current
    )
    formatted_message
  end

  private

  def skip_otel_emit?
    @skip_otel_emit || false
  end

  def severity_number(severity)
    case severity.downcase
    when "debug"
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_DEBUG
    when "info"
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_INFO
    when "warn"
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_WARN
    when "error"
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_ERROR
    when "fatal"
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_FATAL
    else
      OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_UNSPECIFIED
    end
  end
end

# Patch ActiveSupport::Logger to prevent duplicate logs when broadcasting
module ActiveSupportLoggerOTelBridge
  # The ActiveSupport::Logger.broadcast method emits identical logs to
  # multiple destinations. This prevents the broadcasted destinations
  # from generating duplicate OpenTelemetry log records.
  def broadcast(logger)
    logger.instance_variable_set(:@skip_otel_emit, true)
    super
  end
end

# Patch ActiveSupport::BroadcastLogger to prevent duplicate logs
module ActiveSupportBroadcastLoggerOTelBridge
  def add(*args)
    emit_one_broadcast(*args) { super }
  end

  def debug(*args)
    emit_one_broadcast(*args) { super }
  end

  def info(*args)
    emit_one_broadcast(*args) { super }
  end

  def warn(*args)
    emit_one_broadcast(*args) { super }
  end

  def error(*args)
    emit_one_broadcast(*args) { super }
  end

  def fatal(*args)
    emit_one_broadcast(*args) { super }
  end

  def unknown(*args)
    emit_one_broadcast(*args) { super }
  end

  private

  def emit_one_broadcast(*args)
    broadcasts[1..-1].each { |broadcasted_logger| broadcasted_logger.instance_variable_set(:@skip_otel_emit, true) }
    result = yield
    broadcasts.each { |broadcasted_logger| broadcasted_logger.instance_variable_set(:@skip_otel_emit, false) }
    result
  end
end

def parse_resource_attributes(attr_string)
  return {} if attr_string.nil?

  attr_string.split(",").each_with_object({}) do |pair, hash|
    key, value = pair.split("=")
    hash[key] = value
  end
end

resource_attrs = parse_resource_attributes(ENV["OTEL_RESOURCE_ATTRIBUTES"])

# Apply the Logger patch to bridge logs to OpenTelemetry
Logger.prepend(LoggerOTelBridge)

# Apply ActiveSupport::Logger patch to prevent duplicate logs when broadcasting
ActiveSupport::Logger.prepend(ActiveSupportLoggerOTelBridge)

# Apply ActiveSupport::BroadcastLogger patch to prevent duplicate logs
ActiveSupport::BroadcastLogger.prepend(ActiveSupportBroadcastLoggerOTelBridge)

# Configure OpenTelemetry SDK internal logging to file
otel_log_file = Rails.root.join("log", "opentelemetry_sdk.log")
OpenTelemetry.logger = Logger.new(otel_log_file, "daily")
OpenTelemetry.logger.level = Logger::DEBUG
# Prevent infinite loop: don't send OTel SDK's internal logs to OTel
OpenTelemetry.logger.skip_otel_emit = true

OpenTelemetry::SDK.configure do |c|
  SCR = OpenTelemetry::SemanticConventions::Resource

  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    # setting these would take precedence over things set in the OTEL_RESOURCE_ATTRIBUTES env var
    SCR::DEPLOYMENT_ENVIRONMENT => resource_attrs[SCR::DEPLOYMENT_ENVIRONMENT] || Rails.env.to_s,
    SCR::K8S_NAMESPACE_NAME => resource_attrs[SCR::K8S_NAMESPACE_NAME] || ENV.fetch("K8S_NAMESPACE_NAME", ""),
  )

  # setting this would take precedence over the OTEL_SERVICE_NAME env var
  c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "from_config_initializer")

  c.use_all() # enables all instrumentation!
end

# This happens by default in the configuration patch
# Add a metrics reader for OTLP exporter
# metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
# periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: metric_exporter)
# OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)


OTEL_METER = OpenTelemetry.meter_provider.meter("rails-otel-demo-meter")
CONTROLLER_ACCESS_COUNTER = OTEL_METER.create_counter(
  "controller_access",
  unit: "requests",
  description: "Number of times customers#index was accessed"
)

PROCESS_MEMORY_GAUGE = OTEL_METER.create_gauge(
  "process.memory",
  unit: "MB",
  description: "Memory usage of the Rails process in MB"
)

PROCESS_MEMORY_OBSERVED_GAUGE = OTEL_METER.create_observable_gauge(
  "process.memory.observed",
  unit: "MB",
  description: "Memory usage of the process in MB",
  callback: -> {
    mem = GetProcessMem.new
    # puts "THE CALLBACK WAS CALLED! #{Time.now} pid: #{Process.pid} tid: #{Thread.current.object_id} mem: #{mem.mb}"
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
