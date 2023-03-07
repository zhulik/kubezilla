# frozen_string_literal: true

class App::Notifier
  extend Dry::Initializer

  include App

  APPLICATION_ADDED = App::Kubernetes::ApplicationPoller::APPLICATION_ADDED
  APPLICATION_REMOVED = App::Kubernetes::ApplicationPoller::APPLICATION_REMOVED

  option :url, type: T::Strict::String

  def run
    bus.async_subscribe(APPLICATION_ADDED) { send_app_notification(_1, "has been added to kubezilla!") }
    bus.async_subscribe(APPLICATION_REMOVED) { send_app_notification(_1, "has been removed from kubezilla!") }
  end

  private

  def send_app_notification(app, message)
    Async do
      "Kubezilla:\n\n#{app.class} *#{app.metadata.namespace}/#{app.metadata.name}*".then do |header|
        connection.post("", { text: "#{header}\n#{message}" })
      end
    end
  end

  memoize def connection
    Faraday.new(url) do |f|
      f.request :json
      f.response :raise_error
      f.response :json
    end
  end
end
