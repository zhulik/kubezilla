# frozen_string_literal: true

require "bundler/setup"

require "bootsnap"
Bootsnap.setup(cache_dir: "tmp/cache")

Bundler.require(:default)

require "zilla/api/apps_v1_api"
require "zilla/api_client"
require "zilla/version"
require "zilla/configuration"

require "zilla/models/io_k8s_apimachinery_pkg_apis_meta_v1_object_meta"
require "zilla/models/io_k8s_apimachinery_pkg_apis_meta_v1_managed_fields_entry"
require "zilla/models/io_k8s_apimachinery_pkg_apis_meta_v1_label_selector"
require "zilla/models/io_k8s_apimachinery_pkg_apis_meta_v1_list_meta"

require "zilla/models/io_k8s_api_apps_v1_deployment_list"
require "zilla/models/io_k8s_api_apps_v1_deployment"
require "zilla/models/io_k8s_api_apps_v1_deployment_spec"
require "zilla/models/io_k8s_api_apps_v1_deployment_strategy"
require "zilla/models/io_k8s_api_apps_v1_deployment_status"
require "zilla/models/io_k8s_api_apps_v1_deployment_condition"
require "zilla/models/io_k8s_api_apps_v1_rolling_update_deployment"

require "zilla/models/io_k8s_api_core_v1_pod_template_spec"
require "zilla/models/io_k8s_api_core_v1_pod_spec"
require "zilla/models/io_k8s_api_core_v1_container"
require "zilla/models/io_k8s_api_core_v1_env_var"
require "zilla/models/io_k8s_api_core_v1_env_var_source"
require "zilla/models/io_k8s_api_core_v1_secret_key_selector"
require "zilla/models/io_k8s_api_core_v1_probe"
require "zilla/models/io_k8s_api_core_v1_http_get_action"
require "zilla/models/io_k8s_api_core_v1_container_port"
require "zilla/models/io_k8s_api_core_v1_resource_requirements"
require "zilla/models/io_k8s_api_core_v1_volume_mount"
require "zilla/models/io_k8s_api_core_v1_pod_security_context"
require "zilla/models/io_k8s_api_core_v1_volume"
require "zilla/models/io_k8s_api_core_v1_config_map_volume_source"
require "zilla/models/io_k8s_api_core_v1_empty_dir_volume_source"
require "zilla/models/io_k8s_api_core_v1_tcp_socket_action"
require "zilla/models/io_k8s_api_core_v1_security_context"
require "zilla/models/io_k8s_api_core_v1_host_path_volume_source"
require "zilla/models/io_k8s_api_core_v1_secret_volume_source"
require "zilla/models/io_k8s_api_core_v1_capabilities"
require "zilla/models/io_k8s_api_core_v1_toleration"
require "zilla/models/io_k8s_api_core_v1_topology_spread_constraint"
require "zilla/models/io_k8s_api_core_v1_key_to_path"
require "zilla/models/io_k8s_api_core_v1_object_field_selector"
require "zilla/models/io_k8s_api_core_v1_persistent_volume_claim_volume_source"
require "zilla/models/io_k8s_api_core_v1_seccomp_profile"

require "zilla/kubernetes"

loader = Zeitwerk::Loader.for_gem

module App
  class Error < StandardError; end

  module T
    include Dry.Types

    StringLike = (Dry.Types::Strict::String | Dry.Types::Strict::Symbol).constructor(&:to_s)
    KV = Dry.Types::Strict::Hash.map(StringLike, Dry.Types::Strict::String)
  end

  def self.included(base)
    base.include(Async::App::Component)
    base.include(Memery)
  end
end

loader.setup
loader.eager_load
