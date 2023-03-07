# frozen_string_literal: true

class App::Config < Dry::Struct
  include App

  DEFAULT_KUBERNETES_HOST = "127.0.0.1"

  attribute :kubernetes_url, T::Strict::String
  attribute :kubernetes_scheme, T::StringLike

  attribute :notification_webhook_url, T::Strict::String.optional

  class << self
    def build
      kubernetes_host = ENV.fetch("KUBERNETES_SERVICE_HOST", DEFAULT_KUBERNETES_HOST)
      kubernetes_port = ENV.fetch("KUBERNETES_SERVICE_PORT", 8001)
      kubernetes_scheme = kubernetes_host == DEFAULT_KUBERNETES_HOST ? :http : :https

      new(
        kubernetes_url: "#{kubernetes_host}:#{kubernetes_port}",
        kubernetes_scheme:,
        notification_webhook_url: ENV.fetch("NOTIFICATION_WEBHOOK_URL", nil)
      )
    end
  end
end
