# frozen_string_literal: true

class App::Application < Async::App
  include App

  def container_config
    {
      kubernetes: Zilla::Kubernetes.new(host: config.kubernetes_url, scheme: config.kubernetes_scheme)
    }
  end

  def run!
    start_notifier!
    start_deployment_poller!
  end

  private

  def app_name = :kubezilla

  memoize def config = Config.build

  def start_notifier!
    return unless config.notification_webhook_url

    Notifier.new(url: config.notification_webhook_url).run
  end

  def start_deployment_poller! = App::Kubernetes::DeploymentPoller.new.run
end
