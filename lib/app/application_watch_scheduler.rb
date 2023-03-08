# frozen_string_literal: true

class App::ApplicationWatchScheduler
  include App

  APPLICATION_ADDED = App::Kubernetes::ApplicationListPoller::APPLICATION_ADDED

  def run
    bus.subscribe(APPLICATION_ADDED) do |application|
      App::Kubernetes::ApplicationWatcher.new(application:).run
    end
  end
end
