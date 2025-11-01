# Register a build_info observable gauge after Rails finishes initialization.
# The gauge reports a constant quantity of 1 and includes the app version and process ID
Rails.application.config.after_initialize do
  meter = OpenTelemetry.meter_provider.meter("rails-otel-demo-init")

  build_info_gauge = meter.create_observable_gauge(
    "rails_otel_demo_build_info",
    description: "Build information for rails_otel_demo application",
    callback: ->(*args) {
      Rails.logger.debug "build_info callback called at #{Time.now} pid=#{Process.pid} tid=#{Thread.current.object_id} args_count=#{args.length}"
      1
    }
  )

  Rails.logger.debug "Adding attributes to build_info_gauge at #{Time.now} pid=#{Process.pid} tid=#{Thread.current.object_id}"

  build_info_gauge.add_attributes(
    "version" => RailsOTelDemo::VERSION,
    "process.pid" => Process.pid
  )
end
