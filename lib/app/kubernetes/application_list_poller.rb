# frozen_string_literal: true

class App::Kubernetes::ApplicationListPoller
  include App

  include Async::App::TimerComponent

  inject :kubernetes

  def on_tick
    apps = enabled_apps
    added = apps.except(*state.keys).values

    state.replace(apps)

    added.each { App::Kubernetes::ApplicationConfigWatcher.new(application: _1).start! }
  end

  private

  def interval = 3
  def run_on_start = true
  def on_error(exception) = warn { exception }

  memoize def state = {}

  def enabled_apps = fetch_apps.items.select { enabled?(_1) }.index_by { app_key(_1) }
  def fetch_apps = raise NotImplementedError

  def app_key(app) = app.metadata.then { [_1.namespace, _1.name] }
  def enabled?(app) = app.metadata.annotations["kubezilla.enabled"].then { _1 && T::Params::Bool.call(_1) }
end
