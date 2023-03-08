# frozen_string_literal: true

class App::Kubernetes::DeploymentListPoller < App::Kubernetes::ApplicationListPoller
  def fetch_apps = kubernetes.apps_v1_api.list_apps_v1_deployment_for_all_namespaces
end
