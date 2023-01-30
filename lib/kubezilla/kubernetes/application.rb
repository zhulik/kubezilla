# frozen_string_literal: true

class Kubezilla::Kubernetes::Application
  include Kubezilla::Kubernetes
  include Memery

  attr_reader :kind, :json, :client

  def initialize(kind, json, client:)
    @kind = kind
    @json = json
    @client = client
  end

  memoize def scale = @client.public_send("readAppsV1Namespaced#{@kind}Scale", namespace, name)

  memoize def pods
    pod_selector = scale.dig("status", "selector")

    @client.listCoreV1NamespacedPod(namespace, labelSelector: pod_selector)["items"].map do |pod|
      Pod.new(pod, application: self)
    end
  end

  def name = @json.dig("metadata", "name")
  def namespace = @json.dig("metadata", "namespace")
end
