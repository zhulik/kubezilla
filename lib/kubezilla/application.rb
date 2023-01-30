# frozen_string_literal: true

class Kubezilla::Application
  include Kubezilla::Logger

  include Memery

  attr_reader :host, :scheme

  DEFAULT_SLEEP_INTERVAL = 10
  DEFAULT_CYCLE_TIMEOUT = 10
  DEFAULT_POD_ANNOTATION = "diun.enable"

  def initialize(host, scheme)
    @host = host
    @scheme = scheme

    @sleep_interval = ENV.fetch("KUBEZILLA_SLEEP_INTERVAL", DEFAULT_SLEEP_INTERVAL).to_i
    @cycle_timeout = ENV.fetch("KUBEZILLA_CYCLE_TIMEOUT", DEFAULT_CYCLE_TIMEOUT).to_i
    @annotation = ENV.fetch("KUBEZILLA_POD_ANNOTATION", DEFAULT_POD_ANNOTATION).to_s
  end

  def run
    loop do
      Async::Task.current.with_timeout(@cycle_timeout) do
        info { "Looking for updates with timeout of #{@cycle_timeout} seconds..." }
        cycle!
      end
      info { "Sleeping for #{@sleep_interval} seconds..." }
      Async::Task.current.sleep(@sleep_interval)
    rescue StandardError => e
      warn { e }
    end
  end

  private

  def cycle!
    apps = kubernetes.applications

    pods = apps.map { |app| Async { app.pods } }.flat_map(&:wait)

    info { "Found #{apps.count} apps and #{pods.count} pods in total..." }

    check_pods!(pods.select { _1.annotated?(@annotation) })
  end

  def check_pods!(pods)
    images = pods.flat_map(&:images).uniq

    info { "Found #{pods.count} pods and #{images.count} images to watch..." }
    images = images.map do |image|
      Async { { image:, new_digest: needs_update?(image) } }
    end.map(&:wait)
    update_images!(images.select { _1[:new_digest] })
  end

  def update_images!(images)
    info { "Found #{images.count} images to update..." }

    images.map do |image|
      Async { update_image!(**image) }
    end.map(&:wait)
  end

  def update_image!(image:, new_digest:)
    new_digest.split("/")
    info { "Updating image #{image.name} in pod #{image.pod.name} in app #{image.pod.application.name}" }
  end

  def needs_update?(image)
    Kubezilla::Docker::RegistryFactory.for(image).needs_update?(image)
  rescue ArgumentError => e
    error { "Skipping #{image.image}: #{e.message}" }
    false
  end

  memoize def kubernetes = Kubezilla::Kubernetes::Client.new(host:, scheme:)
end
