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

    def log(severity, message, **payload)
      # OpenTelemetry logging implementation goes here
      # For now, just output to demonstrate the backend is working
      puts "[OTel #{severity.upcase}] #{message} #{payload.inspect unless payload.empty?}"
    end
  end
end
