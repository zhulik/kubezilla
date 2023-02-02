# frozen_string_literal: true

class Kubezilla::UpdateWatcher
  include Kubezilla::Logger
  include Memery

  attr_reader :bus

  SLEEP_INTERVAL = ENV.fetch("KUBEZILLA_SLEEP_INTERVAL", 5).to_i

  def initialize(bus:)
    @bus = bus
    @images = {}
  end

  def run
    @bus.async_subscribe(:updatable_images_added, method(:add_images))

    @bus.async_subscribe(:updatable_images_removed, method(:remove_images))

    loop do
      cycle!
    rescue StandardError => e
      warn { e }
    ensure
      info { "Sleeping for #{SLEEP_INTERVAL} seconds" }
      Async::Task.current.sleep(SLEEP_INTERVAL)
    end
  end

  private

  def add_images(payload, **)
    payload[:images].each do |image|
      @images[image.image] = {
        image:,
        deployed_digest: image.digest,
        published_digest: nil
      }
      debug { "Image #{image.image} added to watch" }
    end
  end

  def remove_images(payload, **)
    payload[:images].each do |image|
      @images.delete(image.image)
      debug { "Image #{image.image} removed from watch" }
    end
  end

  def cycle!
    return if @images.empty?

    digests = @images.transform_values do |info|
      Async { published_digest(info[:image]) }
    end.transform_values(&:wait)

    digests.each do |image, digest|
      next unless @images.dig(image, :published_digest) != digest

      @images[image][:published_digest] = digest
      bus.publish(:image_update_found, image: @images[image], digest:)
    end
  end

  def published_digest(image)
    Kubezilla::Docker::RegistryFactory.for(image.registry).published_digest(image)
  rescue ArgumentError => e
    error { "Skipping #{image.image}: #{e.message}" }
    nil
  end
end
