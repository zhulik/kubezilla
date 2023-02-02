# frozen_string_literal: true

class Kubezilla::PodWatcher
  include Kubezilla::Logger
  include Memery

  attr_reader :kubernetes, :bus, :images

  POD_ANNOTATION = ENV.fetch("KUBEZILLA_POD_ANNOTATION", "kubezilla.enabled").to_s
  SLEEP_INTERVAL = ENV.fetch("KUBEZILLA_SLEEP_INTERVAL", 10).to_i

  def initialize(kubernetes:, bus:)
    @kubernetes = kubernetes
    @bus = bus

    @images = []
  end

  def run
    loop do
      cycle!
    rescue StandardError => e
      warn { e }
    ensure
      info { "Sleeping for #{SLEEP_INTERVAL} seconds..." }
      Async::Task.current.sleep(SLEEP_INTERVAL)
    end
  end

  private

  def cycle!
    Async::Task.current.with_timeout(5) do
      images = pods.select { _1.annotated?(POD_ANNOTATION) }
                   .flat_map(&:images).uniq

      new_images = images - @images
      removed_images = @images - images

      @images = images

      bus.publish(:updatable_images_added, images: new_images) if new_images.any?
      bus.publish(:updatable_images_removed, images: removed_images) if removed_images.any?
    end
  end

  def pods = kubernetes.pods
end
