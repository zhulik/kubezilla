# frozen_string_literal: true

class Kubezilla::Kubernetes::Pod
  include Kubezilla::Kubernetes
  include Memery

  attr_reader :json, :client

  def initialize(json, application:)
    @json = json
    @application = application
  end

  memoize def images = @json.dig("status", "containerStatuses").map { Image.new(_1, pod: self) }

  def annotated?(annotation) = @json.dig("metadata", "annotations", annotation)
end
