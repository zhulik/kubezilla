# frozen_string_literal: true

class App::ImagePoller
  include App

  IMAGE_ADDED = App::ApplicationPodWatcher::IMAGE_ADDED
  IMAGE_REMOVED = App::ApplicationPodWatcher::IMAGE_REMOVED

  def run
    bus.subscribe(IMAGE_ADDED) { storage << _1 }
    bus.subscribe(IMAGE_REMOVED) { storage.delete_at(storage.index(_1)) }
    info("Started")
  end

  memoize def storage = []
end
