module RailsOTelDemo
  class Logger
    def self.log(message = nil, **attributes)
      self.logger.on_emit(
        timestamp: Time.now,
        severity_text: "INFO",
        body: message,
        attributes: attributes
      )
    end

    def self.logger
      OpenTelemetry.logger_provider.logger(
        name: "rails_otel_demo",        # scope_name
        version: RailsOTelDemo::VERSION # scope_version
      )
    end
  end
end
