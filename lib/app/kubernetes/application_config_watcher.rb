# frozen_string_literal: true

# TODO: add support for other than Deployment app kinds
# TODO: use watch
module App
  module Kubernetes
    class ApplicationConfigWatcher
      APPLICATION_ADDED = "kubezilla.application.added"
      APPLICATION_REMOVED = "kubezilla.application.removed"
      APPLICATION_CHANGED = "kubezilla.application.changed"

      include App
      include Async::App::TimerComponent
      extend Dry::Initializer

      inject :kubernetes

      option :application, T.Interface(:kind)

      def after_init = update_config!(application)

      def on_tick
        fetch_app.tap do |app|
          next unless version_changed?(app)

          @application = app
          bus.publish("#{APPLICATION_CHANGED}/#{app_id}", application)

          update_config!(app)
        end
      rescue Zilla::ApiError => e
        return stop! if e.code == 404 # app was deleted

        raise
      end

      private

      def interval = 10
      def run_on_start = true
      def on_error(exception) = warn(exception)

      def logger_info = "Application: #{app_namespace}/#{app_name}"

      def app_name = application.metadata.name
      def app_namespace = application.metadata.namespace
      def app_id = "#{app_namespace}/#{app_name}"
      def fetch_app = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(app_name, app_namespace)
      def version_changed?(app) = app.metadata.resource_version != application.metadata.resource_version

      def update_config!(app)
        new_config = App::Kubernetes::ApplicationConfig.for(app)
        old_config = @config
        @config = new_config

        return stop! unless @config.enabled?

        if @timer.active?
          restart! if old_config != new_config
          return
        end

        run!
        bus.publish(APPLICATION_ADDED, application)
      end

      def stop!
        super
        bus.publish("#{APPLICATION_REMOVED}/#{app_id}", application)
      end
    end
  end
end
