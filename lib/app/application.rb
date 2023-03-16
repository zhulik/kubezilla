# frozen_string_literal: true

module App
  class Application < Async::App
    include App

    APPLICATION_ADDED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_ADDED

    def container_config
      {
        config:,
        kubernetes: Zilla::Kubernetes.new(host: config.kubernetes_url, scheme: config.kubernetes_scheme)
      }
    end

    def after_init = bus.subscribe(APPLICATION_ADDED) { ApplicationPodWatcher.new(application: _1).start! }

    private

    def async_app_name = :kubezilla
    memoize def config = Config.build
  end
end
