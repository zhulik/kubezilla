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

    start_image_poller!

    bus.subscribe(APPLICATION_ADDED) { App::ApplicationPodWatcher.new(application: _1).run }

    start_deployment_list_poller!
  end

  private

  def app_name = :kubezilla

  memoize def config = Config.build

  def start_notifier! = Notifier.new(url: config.notification_webhook_url).run
  def start_deployment_list_poller! = App::Kubernetes::DeploymentListPoller.new.run
  def start_application_watch_scheduler! = App::ApplicationWatchScheduler.new.run
  def start_image_poller! = App::ImagePoller.new.run
end
