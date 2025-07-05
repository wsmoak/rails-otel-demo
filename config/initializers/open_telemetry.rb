require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/rails'
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
OpenTelemetry.logger.level = Logger::INFO

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
