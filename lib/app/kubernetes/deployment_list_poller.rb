# frozen_string_literal: true

module App
  module Kubernetes
    class DeploymentListPoller < App::Kubernetes::ApplicationListPoller
      include Async::App::AutoloadComponent

      def fetch_apps = kubernetes.apps_v1_api.list_apps_v1_deployment_for_all_namespaces
    end
  end
end
