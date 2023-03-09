# frozen_string_literal: true

class App::ApplicationPodWatcher
  include App
  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  APPLICATION_REMOVED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_REMOVED
  APPLICATION_CHANGED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_CHANGED

  def run
    @parent = Async::Task.current
    @timer = build_timer

    bus.subscribe(APPLICATION_REMOVED) { stop! }
    bus.subscribe(APPLICATION_CHANGED) do |app|
      @application = app
      restart!
    end
    info { "Started. Polling interval = #{polling_interval}" }
  end

  def call
    pp(fetch_images)
    info { "Call" }
  end

  private

  def polling_interval = App::Kubernetes::ApplicationConfig.for(application).polling_interval

  def restart!
    t = @timer
    @parent.async { @timer = build_timer }
    t.stop
    info { "Restarted. Polling interval=#{polling_interval}" }
  end

  def logger_info = "Application: #{app_namespace}/#{app_name}"
  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace

  def stop!
    info { "Stopped" }
  end

  # def find_images!
  #   fetch_images.tap do |images|
  #     added_images = images - storage
  #     removed_images = storage - images

  #     storage.replace(images)

  #     added_images.each { bus.publish(IMAGE_ADDED, _1) }
  #     removed_images.each { bus.publish(IMAGE_REMOVED, _1) }
  #   end
  # end

  def label_selector = application.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")
  def namespace = application.metadata.namespace

  def fetch_images
    kubernetes.core_v1_api
              .list_core_v1_namespaced_pod(namespace, label_selector:)
              .items
              .reject { _1.metadata.deletion_timestamp }
              .flat_map { _1.status.container_statuses.map { |s| { image: s.image, image_id: s.image_id } } }
              .to_set
  end

  def build_timer = Async::Timer.new(polling_interval, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
end
