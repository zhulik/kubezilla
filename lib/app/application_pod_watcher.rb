# frozen_string_literal: true

class App::ApplicationPodWatcher
  include App
  include Async::App::TimerComponent

  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  APPLICATION_REMOVED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_REMOVED
  APPLICATION_CHANGED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_CHANGED

  def after_init
    bus.subscribe("#{APPLICATION_REMOVED}/#{app_id}") { stop! }
    bus.subscribe("#{APPLICATION_CHANGED}/#{app_id}") do |app|
      @application = app
      restart!
    end
  end

  def on_tick
    pp(fetch_images)
    info { "Tick" }
  end

  private

  def interval = App::Kubernetes::ApplicationConfig.for(application).polling_interval
  def run_on_start = true
  def on_error(exception) = warn(exception)

  def logger_info = "Application: #{app_namespace}/#{app_name}"
  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace
  def app_id = "#{app_namespace}/#{app_name}"

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
end
