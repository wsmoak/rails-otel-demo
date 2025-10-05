# frozen_string_literal: true

require "rails_helper"

RSpec.describe DryLogger::OpenTelemetryBackend do
  subject(:backend) { described_class.new }

  describe "#info" do
    context "when message is present" do
      it "logs a message with info severity" do
        message = "Test info message"
        payload = { user_id: 123, action: "test" }

        expect(backend).to receive(:log).with(:info, message, **payload)

        backend.info(message, **payload)
      end

      it "sends severity_text, body as message, and attributes to the OTel logger" do
        message = "Test info message"
        payload = { user_id: 123, action: "test" }
        otel_logger = instance_double(OpenTelemetry::SDK::Logs::Logger)

        allow(backend).to receive(:otel_logger).and_return(otel_logger)

        expect(otel_logger).to receive(:on_emit).with(
          severity_text: "INFO",
          body: message,
          attributes: { "user_id" => "123", "action" => "test" }
        )

        backend.info(message, **payload)
      end

      it "flattens nested hash attributes before sending to OTel logger" do
        message = "Test with nested payload"
        payload = { user: { id: 123, name: "John" }, metadata: { source: "api", version: 2 } }
        otel_logger = instance_double(OpenTelemetry::SDK::Logs::Logger)

        allow(backend).to receive(:otel_logger).and_return(otel_logger)

        expect(otel_logger).to receive(:on_emit).with(
          severity_text: "INFO",
          body: message,
          attributes: {
            "user.id" => "123",
            "user.name" => "John",
            "metadata.source" => "api",
            "metadata.version" => "2"
          }
        )

        backend.info(message, **payload)
      end
    end

    context "when message is not present" do
      it "sends severity_text, body as JSON payload, and attributes to the OTel logger" do
        payload = { user_id: 123, action: "test" }
        otel_logger = instance_double(OpenTelemetry::SDK::Logs::Logger)

        allow(backend).to receive(:otel_logger).and_return(otel_logger)

        expect(otel_logger).to receive(:on_emit).with(
          severity_text: "INFO",
          body: '{"user_id":123,"action":"test"}',
          attributes: { "user_id" => "123", "action" => "test" }
        )

        backend.info(**payload)
      end

      it "flattens nested hash attributes and uses JSON as body when no message" do
        payload = { user: { id: 123, name: "John" }, metadata: { source: "api", version: 2 } }
        otel_logger = instance_double(OpenTelemetry::SDK::Logs::Logger)

        allow(backend).to receive(:otel_logger).and_return(otel_logger)

        expect(otel_logger).to receive(:on_emit).with(
          severity_text: "INFO",
          body: '{"user":{"id":123,"name":"John"},"metadata":{"source":"api","version":2}}',
          attributes: {
            "user.id" => "123",
            "user.name" => "John",
            "metadata.source" => "api",
            "metadata.version" => "2"
          }
        )

        backend.info(**payload)
      end
    end
  end
end
