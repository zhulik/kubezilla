# frozen_string_literal: true

class App::Notifier
  extend Dry::Initializer

  include App
  include Async::App::AutoloadComponent

  APPLICATION_ADDED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_ADDED
  APPLICATION_REMOVED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_REMOVED

  inject :async_app_name
  inject :config

  def start!
    return if config.notification_webhook_url.nil?

    bus.async_subscribe(APPLICATION_ADDED) { send_app_notification(_1, "has been added to kubezilla!") }
    bus.async_subscribe(APPLICATION_REMOVED) { send_app_notification(_1, "has been removed from kubezilla!") }
    super
  end

  private

  def send_app_notification(app, message)
    "#{async_app_name}:\n\n#{app.class} *#{app.metadata.namespace}/#{app.metadata.name}*".then do |header|
      connection.post("", { text: "#{header}\n#{message}" })
    end
  end

  memoize def connection
    Faraday.new(config.notification_webhook_url) do |f|
      f.request :json
      f.response :raise_error
      f.response :json
    end
  end
end
