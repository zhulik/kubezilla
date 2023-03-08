# frozen_string_literal: true

class App::Kubernetes::ApplicationListPoller
  include App

  inject :kubernetes

  def run
    Async::Timer.new(3, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
    info { "Started" }
  end

  def call
    apps = enabled_apps
    added = apps.except(*state.keys).values

    state.replace(apps)

    added.each { App::Kubernetes::ApplicationConfigWatcher.new(application: _1).run }
  end

  private

  memoize def state = {}

  def enabled_apps = fetch_apps.items.select { enabled?(_1) }.index_by { app_key(_1) }
  def fetch_apps = raise NotImplementedError

  def app_key(app) = app.metadata.then { [_1.namespace, _1.name] }
  def enabled?(app) = app.metadata.annotations["kubezilla.enabled"].then { _1 && T::Params::Bool.call(_1) }
end
