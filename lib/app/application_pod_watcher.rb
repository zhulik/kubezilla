# frozen_string_literal: true

class App::ApplicationPodWatcher
  include App
  extend Dry::Initializer

  inject :kubernetes

  option :application, T.Interface(:kind)

  APPLICATION_REMOVED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_REMOVED
  APPLICATION_CHANGED = App::Kubernetes::ApplicationConfigWatcher::APPLICATION_CHANGED

  IMAGE_ADDED = "kubezilla.pod_image.added"
  IMAGE_REMOVED = "kubezilla.pod_image.removed"

  def run
    find_images!

    bus.subscribe(APPLICATION_REMOVED) { stop! }
    bus.subscribe(APPLICATION_CHANGED) { find_images! }
    info { "Started." }
  end

  private

  def logger_info = "Application: #{app_namespace}/#{app_name}"
  def app_name = application.metadata.name
  def app_namespace = application.metadata.namespace

  def stop!
    storage.each { bus.publish(IMAGE_REMOVED, _1) }
    storage.clear
    info { "Stopped" }
  end

  def find_images!
    fetch_images.tap do |images|
      added_images = images - storage
      removed_images = storage - images

      storage.replace(images)

      added_images.each { bus.publish(IMAGE_ADDED, _1) }
      removed_images.each { bus.publish(IMAGE_REMOVED, _1) }
    end
  end

  def label_selector = application.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")
  def namespace = application.metadata.namespace

  memoize def storage = Set.new

  def fetch_images
    kubernetes.core_v1_api
              .list_core_v1_namespaced_pod(namespace, label_selector:)
              .items
              .reject { _1.metadata.deletion_timestamp }
              .flat_map { _1.status.container_statuses.map(&:image) }
              .to_set
  end
end
