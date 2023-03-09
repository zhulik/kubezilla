# frozen_string_literal: true

class App::Application < Async::App
  include App

  APPLICATION_ADDED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_ADDED

  def container_config
    {
      kubernetes: Zilla::Kubernetes.new(host: config.kubernetes_url, scheme: config.kubernetes_scheme)
    }
  end

  def run!
    start_notifier! if config.notification_webhook_url

    bus.subscribe(APPLICATION_ADDED) { App::ApplicationPodWatcher.new(application: _1).start! }

    start_deployment_list_poller!
  end

  private

  def app_name = :kubezilla

  memoize def config = Config.build

  def start_notifier! = Notifier.new(url: config.notification_webhook_url).start!
  def start_deployment_list_poller! = App::Kubernetes::DeploymentListPoller.new.start!
end
