module RailsOTelDemo
  class Metrics

    OTEL_METER = OpenTelemetry.meter_provider.meter('rails-otel-demo-meter')

    def self.instrument_registry
      @instrument_registry ||= {}
    end

    def self.find_instrument(instrument_name)
      instrument_registry[instrument_name] || raise("Instrument '#{instrument_name}' not found")
    end

    def self.create_counter(name, unit:, description:)
      instrument = OTEL_METER.create_counter(
        instrument_name,
        unit: unit,
        description: description
      )
    end

    def self.create_gauge(name, unit:, description:)
      instrument = OTEL_METER.create_gauge(
        instrument_name,
        unit: unit,
        description: description
      )
    end

    def self.add(instrument_name, value, **attributes)
      instrument = find_instrument(instrument_name)
      instrument.add(value, attributes: attributes)
    end

    def self.record(instrument_name, value, **attributes)
      instrument = find_instrument(instrument_name)
      instrument.record(value, attributes: attributes)
    end
  end
end