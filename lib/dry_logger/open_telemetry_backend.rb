# frozen_string_literal: true

module DryLogger
  class OpenTelemetryBackend
    def debug(message = nil, **payload)
      log(:debug, message, **payload)
    end

    def info(message = nil, **payload)
      log(:info, message, **payload)
    end

    def warn(message = nil, **payload)
      log(:warn, message, **payload)
    end

    def error(message = nil, **payload)
      log(:error, message, **payload)
    end

    def fatal(message = nil, **payload)
      log(:fatal, message, **payload)
    end

    def unknown(message = nil, **payload)
      log(:unknown, message, **payload)
    end

    def close
      # No cleanup needed
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
