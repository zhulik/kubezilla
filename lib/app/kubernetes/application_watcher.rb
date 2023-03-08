# frozen_string_literal: true

# TODO: add support for other than Deployment app kinds
# TODO: parse config and use struct
class App::Kubernetes::ApplicationWatcher
  APPLICATION_ADDED = "kubezilla.application.added"
  APPLICATION_REMOVED = "kubezilla.application.removed"
  APPLICATION_CHANGED = "kubezilla.application.changed"

  include App
  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  class Config < Dry::Struct
    include App

    attribute :enabled, T::Params::Bool

    attribute?(:polling_interval, T::Strict::Float.default(300.0).constructor do |arg|
      arg == Dry::Core::Undefined ? arg : App::IntervalParser.parse(arg)
    end)

    def enabled? = enabled
  end

  # TODO: use watch
  def run
    @parent = Async::Task.current
    @config = nil
    update_config!(parse_config(application))
  end

  def call
    fetch_app.tap do |app|
      next if app.metadata.resource_version == application.metadata.resource_version

      new_config = parse_config(app)
      next if @config == new_config

      update_config!(new_config)
    end
  rescue Zilla::ApiError => e
    return stop! if e.code == 404 # app was deleted

    raise
  end

  private

  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace
  def fetch_app = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(app_name, app_namespace)

  def parse_config(app)
    Config.new(
      **app.metadata
           .annotations
           .select { _1.start_with?("kubezilla") }
           .transform_keys { _1[10..].to_sym }
    )
  end

  def update_config!(new_config) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @config = new_config

    return stop! unless @config.enabled?

    # Start timer if not started
    if @timer.nil?
      @timer = build_timer
      bus.publish(APPLICATION_ADDED, application)
      return info { "Started. Polling interval=#{@config.polling_interval}" }
    end

    # config changed, stop existing timer, start a new one
    bus.publish(APPLICATION_CHANGED, application)
    t = @timerpolling_interval
    @parent.async { @timer = build_timer }
    t.stop
    info { "Restarted. Polling interval=#{@config.polling_interval}" }
  end

  def stop!
    @timer&.stop
    info { "Stopped" }
    bus.publish(APPLICATION_REMOVED, application)
  end

  def logger_info = "Application: #{app_namespace}/#{app_name}"

  def build_timer
    Async::Timer.new(@config.polling_interval, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
  end
end
