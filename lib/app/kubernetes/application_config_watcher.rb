# frozen_string_literal: true

# TODO: add support for other than Deployment app kinds
class App::Kubernetes::ApplicationConfigWatcher
  APPLICATION_ADDED = "kubezilla.application.added"
  APPLICATION_REMOVED = "kubezilla.application.removed"
  APPLICATION_CHANGED = "kubezilla.application.changed"

  include App
  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  # TODO: use watch
  def run
    @parent = Async::Task.current
    @config = nil
    update_config!(application)
  end

  def call
    fetch_app.tap do |app|
      next if app.metadata.resource_version == application.metadata.resource_version

      @application = app
      bus.publish(APPLICATION_CHANGED, application)

      update_config!(app)
    end
  rescue Zilla::ApiError => e
    return stop! if e.code == 404 # app was deleted

    raise
  end

  private

  def logger_info = "Application: #{app_namespace}/#{app_name}"
  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace
  def fetch_app = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(app_name, app_namespace)

  def update_config!(app)
    new_config = App::Kubernetes::ApplicationConfig.for(app)
    old_config = @config
    @config = new_config

    return stop! unless @config.enabled?

    # Start timer if not started
    if @timer.nil?
      @timer = build_timer
      bus.publish(APPLICATION_ADDED, application)
      return info { "Started. Polling interval=#{@config.polling_interval}" }
    end

    # config changed restart timer
    restart! if old_config != new_config
  end

  def stop!
    @timer&.stop
    info { "Stopped" }
    bus.publish(APPLICATION_REMOVED, application)
  end

  def restart!
    t = @timer
    @parent.async { @timer = build_timer }
    t.stop
    info { "Restarted. Polling interval=#{@config.polling_interval}" }
  end

  def build_timer
    Async::Timer.new(@config.polling_interval, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
  end
end
