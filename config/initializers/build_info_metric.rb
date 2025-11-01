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

  meter = OpenTelemetry.meter_provider.meter("rails-otel-demo-init")
  build_info_gauge = meter.create_observable_gauge(
    "rails_otel_demo_build_info",
    description: "Build information for rails_otel_demo (observable gauge)",
    callback: ->(*args) {
      Rails.logger.info "build_info callback called at #{Time.now} version=#{version} pid=#{Process.pid} tid=#{Thread.current.object_id} args_count=#{args.length}"
      1
    }
  )

  Rails.logger.info "Adding attributes to build_info_gauge at #{Time.now} version=#{version} pid=#{Process.pid} tid=#{Thread.current.object_id}"
  build_info_gauge.add_attributes(
    "version" => version,
    "testing" => "add_attributes 903"
  )
end
