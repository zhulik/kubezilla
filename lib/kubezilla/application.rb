# frozen_string_literal: true

class Kubezilla::Application
  include Kubezilla::Logger

  include Memery

  attr_reader :host, :scheme

  SERVICE_HOST = ENV.fetch("KUBERNETES_SERVICE_HOST", nil)
  SERVICE_PORT = ENV.fetch("KUBERNETES_SERVICE_PORT", nil)

  def initialize(host = nil, scheme = :https)
    @host = host || "#{SERVICE_HOST}:#{SERVICE_PORT}"
    @scheme = scheme
  end

  def run
    print_logs

    Async { update_watcher.run }

    pod_watcher.run
  end

  private

  memoize def pod_watcher = Kubezilla::PodWatcher.new(kubernetes:, bus:)
  memoize def update_watcher = Kubezilla::UpdateWatcher.new(bus:)

  def print_logs
    bus.async_subscribe(:updatable_images_added) do |payload|
      info { "#{payload[:images].count} images added" }
    end

    bus.async_subscribe(:updatable_images_removed) do |payload|
      info { "#{payload[:images].count} images removed" }
    end
  end

  # def update_images!(images)
  #   info { "Found #{images.count} images to update..." }

  #   images.map do |image|
  #     Async { update_image!(**image) }
  #   end.map(&:wait)
  # end

  # def update_image!(image:, new_digest:)
  #   new_digest.split("/")
  #   info { "Updating image #{image.name} in pod #{image.pod.name} in app #{image.pod.application.name}" }
  # end

  memoize def kubernetes = Kubezilla::Kubernetes::Client.new(host:, scheme:)
  memoize def bus = Async::Bus.get
end
