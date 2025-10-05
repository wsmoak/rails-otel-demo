# frozen_string_literal: true

module ApplicationLogger
  # Creates a Dry::Logger instance with OpenTelemetry backend
  #
  # @param id [String, Symbol] The logger identifier
  # @return [Dry::Logger::Dispatcher]
  def self.build(id)
    Dry.Logger(id) do |dispatcher|
      dispatcher.add_backend(DryLogger::OpenTelemetryBackend.new)
    end
  end
end
