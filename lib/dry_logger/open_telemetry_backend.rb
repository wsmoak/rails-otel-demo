# frozen_string_literal: true

module DryLogger
  class OpenTelemetryBackend
    VALID_SEVERITIES = %i[debug info warn error fatal unknown].freeze

    def method_missing(method_name, message = nil, **payload)
      if VALID_SEVERITIES.include?(method_name)
        log(method_name, message, **payload)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      VALID_SEVERITIES.include?(method_name) || super
    end

    private

    def otel_logger
      @otel_logger ||= OpenTelemetry.logger_provider.logger(name: "rails_otel_demo", version: "0.1.0")
    end

    def log(severity, message, **payload)
      puts "THE PAYLOAD IS: #{payload.inspect}"
      payload.deep_stringify_keys!
      payload = flatten_hash(payload)
      payload.transform_values!(&:to_s)
      puts "NOW THE PAYLOAD IS: #{payload.inspect}"

      otel_logger.on_emit(
        severity_text: severity.to_s.upcase,
        body: message,
        attributes: payload
      )
    end

    def flatten_hash(hash, separator = ".")
      hash.each_with_object({}) do |(key, value), result|
        if value.is_a?(Hash)
          flatten_hash(value, separator).each do |nested_key, nested_value|
            result["#{key}#{separator}#{nested_key}"] = nested_value
          end
        else
          result[key] = value
        end
      end
    end
  end
end
