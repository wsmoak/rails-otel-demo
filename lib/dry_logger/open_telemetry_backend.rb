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
      payload.transform_keys!(&:to_s)

      otel_logger.on_emit(
        severity_text: severity.to_s.upcase,
        body: message,
        attributes: payload
      )
    end
  end
end
