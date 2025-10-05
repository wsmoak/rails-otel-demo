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

    # Note: this duplication can be removed by using method_missing.

    def close
      # No cleanup needed
    end

    private

    def otel_logger
      @otel_logger ||= OpenTelemetry.logger_provider.logger(name: "rails_otel_demo", version: "0.1.0")
    end

    def log(severity, message, **payload)
      severity_text = severity.to_s.upcase
      json_payload = payload.to_json

      payload.deep_stringify_keys!
      payload = flatten_hash(payload)
      payload.transform_values!(&:to_s)

      if message.present?
        otel_logger.on_emit(
          severity_text: severity_text,
          body: message,
          attributes: payload
        )
      else
        otel_logger.on_emit(
          severity_text: severity_text,
          body: json_payload,
          attributes: payload
        )
      end
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
