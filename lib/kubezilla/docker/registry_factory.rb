# frozen_string_literal: true

module Kubezilla::Docker::RegistryFactory
  include Kubezilla::Docker

  REGISTRIES = {
    "docker.io" => Registries::Docker.new
  }.freeze

  def self.for(image)
    REGISTRIES[image.registry].tap do |registry|
      raise ArgumentError, "registry #{image.registry} is unknown" if registry.nil?
    end
  end
end
