# Rails OpenTelemetry Demo

## Configuring OpenTelemetry Logging in a Rails Application

OpenTelemetry provides powerful observability capabilities for Rails applications. Let's explore how to configure logging.

### Basic Setup

Create a Rails app with `rails new -T rails-otel-demo`

The configuration lives in [config/initializers/open_telemetry.rb](config/initializers/open_telemetry.rb) and demonstrates several key concepts:

```ruby
OpenTelemetry::SDK.configure do |c|
  # Configuration goes here
end
```

(The examples I found use `opentelemetry.rb` for this filename but the official project name is OpenTelemetry so by convention it should have the underscore.)

### Resource Attributes

The OTel Ruby SDK supports many of the standard OTel environment variables.  You can find a list of them in the [spec compliance matrix](https://github.com/open-telemetry/opentelemetry-specification/blob/main/spec-compliance-matrix.md#environment-variables).

For example if you are using the `OTEL_RESOURCE_ATTRIBUTES` environment variable, it should have the following format for the value:
```sh
OTEL_RESOURCE_ATTRIBUTES="k8s.namespace.name=the-namespace,k8s.pod.uid=a2b3c4d5-e6f7"
```

### Configuration Precedence

By default, values set in the code will override values set in environment variables.  The code in this example is written to prefer the OTel standard environment variables and fall back to a value set in the code if necessary.

1. Environment variables (like `OTEL_SERVICE_NAME` and `OTEL_SERVICE_ATTRIBUTES`)
2. Programmatic configuration
3. Default values

For example:
```ruby
c.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'from_config_initializer')
```

Then if you run the app with
```bash
$ OTEL_LOGS_EXPORTER=otlp OTEL_SERVICE_NAME=from_envar bundle exec rails server -p 3001
```
you will see that the service_name label in Loki is set to `from_envar` rather than `from_config_initializer`.

Similarly if you know that the Kubernetes Namespace Name is set as `K8S_NAMESPACE` in your deployed environment, you can write

```ruby
  SCR = OpenTelemetry::SemanticConventions::Resource

  SCR::K8S_NAMESPACE_NAME => resource_attrs[SCR::K8S_NAMESPACE_NAME] || ENV.fetch('K8S_NAMESPACE', 'unknown_namespace')
```

(The code for parsing the resource attributes from the environment variable is in `config/initializers/open_telemetry.rb`.)

This can help if other parts of your CI/CD process are injecting enviroment variables other than the standard ones, and/or you are using a service such as Seekrit or Doppler to control them.

### Semantic Conventions

The code uses OpenTelemetry's semantic conventions for standardized attribute naming:

```ruby
c.resource = OpenTelemetry::SDK::Resources::Resource.create(
  OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT => Rails.env.to_s
)
```

When running the app locally, this sets `deployment.environment` to `development`, which shows up as the value for the `deployment_environment` label in Loki.

### Types

Note that with the Ruby SDK, all the attribute keys must be strings, and all the values must be string or number (or arrays of strings or numbers).

Simply using `Rails.env` as the value of an attribute will NOT work!  It has a string representation that looks like what we need, but it is NOT a String.

```ruby
$ bundle exec rails console

rails-otel-demo(dev)> Rails.env
=> "development"

rails-otel-demo(dev)> Rails.env.class
=> ActiveSupport::EnvironmentInquirer
```

### Grafana docker-otel-lgtm

To see the logs show up in Loki using Grafana locally, try out Grafana's docker-otel-lgtm project:

```bash
git clone https://github.com/grafana/docker-otel-lgtm.git
cd docker-otel-lgtm
./run-lgtm.sh
```

Then visit http://localhost:3000

Note that the default port for the Rails app is also 3000, so start the Rails app on port 3001 to avoid a conflict.

### Inflections

Don't forget to un-comment the code in `config/initializers/inflections.rb` and add one for OTel.  Otherwise, if you have any names with `_otel` it will get capitalized as Otel which is incorrect.

```ruby
  ActiveSupport::Inflector.inflections(:en) do |inflect|
    inflect.acronym "RESTful"
    inflect.acronym "OTel"
  end
```

### References

- OpenTelemetry Ruby in GitHub https://github.com/open-telemetry/opentelemetry-ruby
- [semantic_conventions/resource.rb](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/semantic_conventions/lib/opentelemetry/semantic_conventions/resource.rb) for standard attribute names
- The official OpenTelemetry documentation for Ruby https://opentelemetry.io/docs/languages/ruby/
- https://opentelemetry.io/docs/languages/ruby/getting-started/
- [Steven Harman's post in #otel-ruby in the CNCF Slack from January 2003 showing how to configure resource attributes](https://cloud-native.slack.com/archives/C01NWKKMKMY/p1674566998568639?thread_ts=1674560943.812979&cid=C01NWKKMKMY)
- [Kayla Reopelle's announcement about logging support in the Ruby SDK in #otel-ruby in the CNCF Slack from December 2024](https://cloud-native.slack.com/archives/C01NWKKMKMY/p1733516156143249)
- If you can't see the Slack messages, [get an invitation to the CNCF Slack](https://slack.cncf.io)
- https://opentelemetry.io/docs/languages/sdk-configuration/general/

### AI

I used Anthropic's Claude 3.5 Sonnet for help with some of the code and to draft this blog post.  It really is awesome.  Keep notes in the README.md file of a project while you are learning something new, and then ask it (using the VS Code Github Copilot plugin) "@workspace look at the open_telemetry.rb, logger.rb, and README.md files and write a blog post explaining what I've learned".

## Configuring OpenTelemetry Metrics in a Rails Application

Now let's explore how to add metrics to the example Rails app using the OTel Ruby SDK.

Add the metrics gems to Gemfile:
```
gem "opentelemetry-metrics-sdk", "~> 0.8.0"
gem "opentelemetry-exporter-otlp-metrics", "~> 0.6.0"
```

Create a counter:
```
OTEL_METER = OpenTelemetry.meter_provider.meter('rails-otel-demo-meter')

CONTROLLER_ACCESS_COUNTER = OTEL_METER.create_counter(
  'controller_access',
  unit: 'requests',
  description: 'Number of times customers#index was accessed'
)
```

In Prometheus, the metric for a counter will appear as `<name>_<unit>_total`.

Later, add to the counter:
```
    CONTROLLER_ACCESS_COUNTER.add(
        1,
        attributes: {
            'host.name' => Socket.gethostname,
            'controller' => 'customers',
            'action' => 'index'
            'fruit' => ['peach', 'apple', 'cherry', 'banana'].sample
        }
    )
```

When choosing attributes, be mindful of the cardinality.

Start the app with:
`$ OTEL_LOGS_EXPORTER=otlp OTEL_METRICS_EXPORTER=otlp OTEL_METRIC_EXPORT_INTERVAL=20000 OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative PORT=3001 bundle exec rails server`

(Or use the dotenv-rails gem and set these in the .env.development file.)

## Logger Bridge

This application implements a bridge between Ruby's Logger and OpenTelemetry logs, allowing standard Rails logging calls to automatically send log data to OpenTelemetry.

This implementation is based on the OpenTelemetry Ruby Logger instrumentation from:
- [opentelemetry-ruby-contrib PR #983](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/983) by the OpenTelemetry community

As mentioned in that PR, it is similar to the approach used in [newrelic-ruby-agent PR #1019](https://github.com/newrelic/newrelic-ruby-agent/pull/1019)

### Implementation

The logger bridge patches three classes in `config/initializers/open_telemetry.rb`:

1. **Logger** - Intercepts `format_message` to emit logs to OpenTelemetry's logger provider with proper severity mapping
2. **ActiveSupport::Logger** - Prevents duplicate logs when using the `broadcast` method
3. **ActiveSupport::BroadcastLogger** - Ensures only one logger emits to OpenTelemetry when Rails broadcasts logs to multiple destinations

### How It Works

When you call `Rails.logger.info "message"`, the patched Logger:
1. Formats the message normally
2. Maps the severity level (debug/info/warn/error/fatal) to OpenTelemetry's SeverityNumber
3. Emits the log to OpenTelemetry with the current context
4. Returns the formatted message

The `ActiveSupport::BroadcastLogger` patch is critical for Rails applications, as Rails uses broadcast logging to send logs to multiple destinations (console, files, etc.). Without this patch, each broadcasted logger would emit to OpenTelemetry, creating duplicate log entries. The patch temporarily sets `@skip_otel_emit = true` on all broadcast destinations except the first, ensuring only one emission per log statement.
