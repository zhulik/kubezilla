# frozen_string_literal: true

# TODO: add support for other than Deployment app kinds
# TODO: parse config and use struct
class App::Kubernetes::ApplicationWatcher
  include App
  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  # TODO: use watch
  def run = update_config!(parse_config(application))

  def call
    fetch_app.tap do |app|
      next if app.metadata.resource_version == application.metadata.resource_version

      new_config = parse_config(app)
      next if config == new_config

      update_config!(new_config)
    end
  end

  private

  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace
  def fetch_app = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(app_name, app_namespace)

  memoize def config = {}
  def parse_config(app) = app.metadata.annotations.select { _1.start_with?("kubezilla") }

  def update_config!(new_config)
    config.replace(new_config)
    # TODO: send event
    return stop! unless config["kubezilla.enabled"] == "true"

    # Start timer if not started
    if @timer.nil?
      @timer = build_timer
      return info { "Started" }
    end

    # config changed, stop existing timer, start a new one
    @timer.stop
    @timer = build_timer
    info { "Restarted" }
  end

  def stop!
    # TODO: send event
    @timer&.stop
    info { "Stopped" }
  end

  def logger_info = "Application: #{app_namespace}/#{app_name}"

  def build_timer = Async::Timer.new(3, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
end
