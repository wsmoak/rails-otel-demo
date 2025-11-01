# Register a build-info observable gauge after Rails finishes initialization.
# The gauge reports a constant quantity of 1 and includes the app version
# as an attribute called "version".
Rails.application.config.after_initialize do
  # Determine version from the application module if available
  version = if defined?(RailsOTelDemo) && RailsOTelDemo.const_defined?(:VERSION)
    RailsOTelDemo::VERSION
  else
    # fall back to a string if we can't determine a version
    "unknown"
  end

  # Ensure the meter from the OpenTelemetry initializer is available
  if defined?(OTEL_METER)
    build_info_gauge = OTEL_METER.create_observable_gauge(
      "rails_otel_demo_build_info",
      description: "Build information for rails_otel_demo (observable gauge)",
      # callback returns the observed numeric value (quantity = 1)
      callback: -> { 1 }
    )

    # Observe once and include the version as an attribute. The value is always 1.
    build_info_gauge.observe(
      attributes: {
        "version" => version,
        "testing" => "826"
      }
    )
  else
    Rails.logger.warn("OTEL_METER not defined; rails_otel_demo_build_info metric not registered")
  end
end
