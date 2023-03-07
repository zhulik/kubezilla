# frozen_string_literal: true

class App::Kubernetes::ApplicationPoller
  include App

  inject :kubernetes

  APPLICATION_ADDED = "kubezilla.application.added"
  APPLICATION_REMOVED = "kubezilla.applications.removed"

  def run
    Async::Timer.new(30, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
    info { "Started" }
  end

  def call
    apps = enabled_apps
    added = apps.values_at(*(apps.keys - state.keys))
    removed = state.values_at(*(state.keys - apps.keys))

    state.replace(apps)

    publish_app_event(APPLICATION_ADDED, added)
    publish_app_event(APPLICATION_REMOVED, removed)
  end

  private

  memoize def state = {}

  def enabled_apps = fetch_apps.items.select { enabled?(_1) }.index_by { app_key(_1) }
  def fetch_apps = raise NotImplementedError

  def app_key(app) = app.metadata.then { [_1.namespace, _1.name] }
  def enabled?(app) = app.metadata.annotations["kubezilla.enabled"].then { _1 && T::Params::Bool.call(_1) }
  def publish_app_event(event_name, apps) = apps.each { bus.publish(event_name, _1) }
end
